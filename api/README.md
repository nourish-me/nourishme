# NourishMe API Proxy

Thin Cloudflare Worker that sits between the Flutter app and the Anthropic
Messages API, so the Anthropic key never ships in the app bundle.

## Architecture

```
Flutter app  ──(POST /messages, x-app-secret)──▶  Cloudflare Worker
                                                         │
                                                         ▼
                                                  Anthropic API
                                                  (x-api-key from
                                                   Worker secret)
```

## Deployment (one-time setup)

```bash
# 1. Install wrangler CLI globally
npm install -g wrangler

# 2. Log into Cloudflare (opens browser)
wrangler login

# 3. From this folder
cd api

# 4. Set the secrets. wrangler will prompt for the value of each:
wrangler secret put ANTHROPIC_API_KEY
# Paste your sk-ant-... key

wrangler secret put APP_SECRET
# Generate a random value, e.g.:
#   openssl rand -base64 32
# Save this exact value — you'll paste it into the app's .env

# 5. Deploy
wrangler deploy
```

Wrangler will print the deployment URL, something like:

```
https://nourishme-api.<your-account>.workers.dev
```

Copy that URL.

## Hooking up the app

Edit `/Users/vanessa.heizmann/Projects/nurturetrack/.env`:

```
NOURISHME_API_URL=https://nourishme-api.<your-account>.workers.dev
APP_SECRET=<the random value you put into the Worker secret>
```

(Remove `ANTHROPIC_API_KEY` from `.env` once the proxy is verified — you
don't want the key on the device any more.)

Rebuild / redeploy the app. All Claude calls now go through the Worker.

## Test it

```bash
# Health check (no auth)
curl https://nourishme-api.<your-account>.workers.dev/health
# {"status":"ok"}

# Forbidden without secret
curl -X POST https://nourishme-api.<your-account>.workers.dev/messages \
  -H "content-type: application/json" \
  -d '{"model":"claude-haiku-4-5-20251001","max_tokens":50,"messages":[{"role":"user","content":"hi"}]}'
# {"error":"Forbidden"}

# Works with secret
curl -X POST https://nourishme-api.<your-account>.workers.dev/messages \
  -H "content-type: application/json" \
  -H "x-app-secret: <APP_SECRET>" \
  -d '{"model":"claude-haiku-4-5-20251001","max_tokens":50,"messages":[{"role":"user","content":"hi"}]}'
# {"id":"msg_...", "content":[...]}
```

## Rotating the app secret

If the secret leaks (someone unpacks the IPA), rotate:

```bash
wrangler secret put APP_SECRET
# new value
wrangler deploy
```

Update `.env`, rebuild app. Old builds stop working — by design.

## Cost telemetry + circuit breaker

The worker logs every call's token usage and enforces a daily global call cap.

**Live view (no setup needed):** every call prints a structured line you can
watch in real time:

```bash
cd api
wrangler tail
# {"event":"api_call","callType":"coach","status":200,"inputTokens":1004,"outputTokens":210,"ts":"..."}
```

`callType` is one of `parse`, `coach`, `photo`, `chat`, `safety` (sent by the
app via the `x-call-type` header). Photo calls carry image tokens, so they're
the expensive ones — this split is what validates the pricing model.

**Daily aggregate + circuit breaker (needs a KV namespace):**

```bash
cd api
wrangler kv namespace create BUDGET
# Copy the printed id into wrangler.toml: uncomment the [[kv_namespaces]]
# block and paste the id, then redeploy:
wrangler deploy
```

Once bound, the worker keeps a per-day record `day:YYYY-MM-DD` with
`{calls, in, out}` (token totals) and returns HTTP 429 once `calls` exceeds
`MAX_CALLS_PER_DAY` (default 800, set in `wrangler.toml`). This is a
runaway-loop safety net, **not** subscription/quota logic. Read a day's
spend with:

```bash
wrangler kv key get --binding BUDGET "day:2026-05-27"
# {"calls":42,"in":51230,"out":8900}
```

Cost = `in / 1e6 * $1.00 + out / 1e6 * $5.00` (claude-haiku-4-5 rates).

Until the KV namespace is bound the worker still runs — logging works, the cap
is simply skipped.

## Safety system-prompt block (Task #88.2)

Every `/messages` call gets a server-side safety block prepended to the
client's `system` field BEFORE it goes to Anthropic. Defines:

- general info / no medical advice / no diagnosis / no dosing
- escalation to midwife / doctor for medical topics
- emergency-keyword handling (heavy bleeding etc. → 112, no nutrition tip)
- veto on recommending blocklist items (alcohol, raw animal products, etc.)
- "when in doubt, the more cautious answer"

The block is hardcoded in the Worker (`SAFETY_BLOCK_DE` / `SAFETY_BLOCK_EN`),
which means the client cannot bypass it: rotating the safety wording only
needs a `wrangler deploy`, no App Store update.

Locale comes from the `x-locale: de|en` request header the app sends;
defaults to `en` if missing (so an old client paired with a new Worker
still gets a working safety floor, just in English).

Unit test for the prepend logic (no Cloudflare runtime needed):

```bash
node --test api/test-injection.test.mjs
# 13/13 tests covering shape handling, locale selection, content invariants
```

## Audit logging (Task #88.7)

DSGVO-konform: every log line carries the pseudonymous user hash and
ZERO raw user input or model output. The contract is enforced by the
shared `auditEvent({...})` helper — emit sites that need to log something
new MUST go through it.

What gets logged today:

```jsonc
// Every API call (existing telemetry, now hashed):
{"event":"api_call","ruleId":null,"callType":"coach","userHash":"3a7b2c...","ts":"...",
 "status":200,"inputTokens":1004,"outputTokens":210}

// Daily call cap tripped:
{"event":"budget_cap_hit","ruleId":null,"callType":"coach","userHash":"3a7b2c...","ts":"...",
 "day":"day:2026-06-15","calls":800,"cap":800}
```

Reserved event names for future safety emit-sites (wired up by Tasks
#88.3 input-classifier and #88.4 output-post-check):

- `audit_emergency` — input matched a 112-tier keyword
- `audit_escalation` — input matched a medical-handoff keyword
- `audit_blocked` — model output recommended a blocklist item

User hash: `SHA-256(install_id + ':' + APP_SECRET)` truncated to 16 hex
chars. Stable per install, irreversible without the Worker secret.
Missing `x-install-id` header (older client) logs as `userHash: 'anon'`.

Unit test:

```bash
node --test api/test-logging.test.mjs
# 8 tests covering hash determinism, salt-effect, defensive defaults
```

## Input pre-classifier (Task #88.3)

Two-tier symptom classifier runs BEFORE every Anthropic call:

- **Emergency** (heavy bleeding, preterm labour, no baby movement,
  fainting, vision changes): synthesises an Anthropic-shaped response
  with the canned 112 / clinic message, NO upstream call, audit-logs
  `audit_emergency` with the matched keyword.
- **Escalation** (medication, gestational diabetes, mastitis,
  postpartum depression etc.): same shape, message points to
  midwife/doctor, audit-logs `audit_escalation`.

Emergency takes precedence when both stages would match. Only the LATEST
user message is classified - chat history containing the keyword from a
prior turn doesn't re-fire forever.

Synthesised responses carry a non-Anthropic field `nourishme_response_type`
that the Flutter client uses to render the bubble in escalation/emergency
style instead of as a normal coach reply. Anthropic ignores unknown
top-level fields so the client always sees this field.

The Flutter client runs the SAME classifier preflight via
`SafetyRules.classifyInput(...)` and short-circuits there too - faster UX
and saves the round-trip. The Worker check is defense in depth for
tampered / stale / non-Flutter clients.

Keyword lists in this file (`EMERGENCY_KEYWORDS`, `ESCALATION_KEYWORDS`,
`EMERGENCY_RESPONSES`, `ESCALATION_RESPONSES`) MUST stay in sync with
the `inputTriggers` section of `assets/safety-rules.json`.

Unit test:

```bash
node --test api/test-classify-input.test.mjs
# 19 tests covering both stages, locale fallback, last-message picking,
# precedence, defensive shapes, keyword-list integrity
```

## Output post-check (Tier 1, Task #88.4)

After every successful upstream call, the Worker scans the model's text
content for `(blocklist_keyword AND recommendation_phrase)` in the same
sentence. On match the response is REPLACED with a synth `blocked`
fallback ("I'd rather not give you advice on that, please talk it through
with your midwife or doctor"), `audit_blocked` is logged with the matched
`keyword+phrase` rule-id, and the client renders the bubble in the
shielded "blocked" style.

What "same sentence" means: text is split on `[.!?\n;]+`. So
"Vermeide Tatar. Lachs ist okay." does NOT trip the check (Tatar lives
in a warning sentence, "ist okay" in a separate sentence about salmon).

Keyword list is intentionally a CURATED SUBSET of the full
`assets/safety-rules.json` universe - only items the model is realistically
tempted to recommend (alcohol, tatar, sushi, brie, camembert, raw cheese
classics, tuna, swordfish, liver, spirulina, tonic water, wild boar).
Obscure compounds are covered by the input-side deterministic rules + the
system-prompt safety block; the post-check stays surgical to keep false-
positive rate near zero.

Both DE+EN phrase sets are always checked because models sometimes mix
languages mid-reply.

Unit test:

```bash
node --test api/test-classify-output.test.mjs
# 14 tests covering blocking cases, warning-sentence passes, mixed-language
# hits, list integrity
```

## Cost / limits

Cloudflare Workers free tier: 100 000 requests/day. Easily covers ~1 000
beta testers.

Anthropic spend: claude-haiku-4-5 at ~$0.003 per coach response.
Monitor at https://console.anthropic.com/settings/usage.

## Why not Supabase / a real backend

We deliberately chose the thinnest possible proxy. The app keeps its
local-first storage (Hive), no user accounts, no synced data. The Worker
exists only to hide the Anthropic key. If we later add accounts /
sync, we can layer that on (or migrate to Supabase).
