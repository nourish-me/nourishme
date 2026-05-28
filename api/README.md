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
