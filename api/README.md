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
