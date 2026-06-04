// NourishMe API proxy
//
// Cloudflare Worker that forwards POST requests from the app to the
// Anthropic Messages API. The Anthropic API key lives only in Worker
// secrets, never in the app bundle.
//
// Auth: the app sends an `x-app-secret` header containing a shared secret.
// This is security-through-obscurity (the secret is still embedded in the
// app and extractable) but it limits casual abuse and lets us rotate the
// secret without touching the Anthropic key. Cloudflare's per-IP rate
// limiting on the free tier provides additional protection.
//
// Cost telemetry: every call's token usage is logged as a structured line
// (visible live via `wrangler tail`) and, when the BUDGET KV namespace is
// bound, aggregated into a per-day record. The app labels each call via the
// `x-call-type` header (parse / coach / photo / chat / safety) so we can see
// the COGS split during the beta and validate the pricing model with real
// numbers instead of guesses.
//
// Circuit breaker: a global per-day call cap (MAX_CALLS_PER_DAY) returns 429
// once exceeded. This is a runaway-loop safety net, NOT subscription/quota
// logic (that's a public-launch concern). Set the cap well above expected
// beta volume. Degrades gracefully: if the BUDGET KV namespace isn't bound,
// the cap is skipped and only console logging runs.
//
// Endpoints:
//   POST /messages   → forwards to api.anthropic.com/v1/messages
//   GET  /health     → simple liveness check (no auth)
//
// Deployment: see README.md in this folder.

const ANTHROPIC_ENDPOINT = 'https://api.anthropic.com/v1/messages';
const ANTHROPIC_VERSION = '2023-06-01';
const DEFAULT_MAX_CALLS_PER_DAY = 800;
const DAY_RECORD_TTL_SECONDS = 90 * 24 * 60 * 60; // keep ~90 days of history

function utcDayKey(now) {
  return `day:${now.toISOString().slice(0, 10)}`; // day:YYYY-MM-DD
}

function jsonResponse(obj, status) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { 'content-type': 'application/json' },
  });
}

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    // Health check (unauthenticated).
    if (request.method === 'GET' && url.pathname === '/health') {
      return jsonResponse({ status: 'ok' }, 200);
    }

    // Cost summary readout. Secured by the same APP_SECRET so the beta
    // dashboard can call it without exposing per-day spend to anyone who
    // happens to know the Worker URL. Returns the last N days (default 7,
    // max 30) of token aggregates with derived USD cost. Drives L3 of the
    // beta learning goals (cost per active user per week).
    if (request.method === 'GET' && url.pathname === '/budget/summary') {
      const secret = request.headers.get('x-app-secret');
      if (!env.APP_SECRET || !secret || secret !== env.APP_SECRET) {
        return jsonResponse({ error: 'Forbidden' }, 403);
      }
      if (!env.BUDGET) {
        return jsonResponse(
          { error: 'BUDGET KV namespace not bound on this Worker.' },
          503,
        );
      }
      const requestedDays = Number(url.searchParams.get('days')) || 7;
      const days = Math.max(1, Math.min(30, requestedDays));
      // Claude Haiku 4.5 pricing (per 1M tokens). When we switch model,
      // update both lines AND the model constant referenced in the app.
      const INPUT_USD_PER_MTOK = 1.0;
      const OUTPUT_USD_PER_MTOK = 5.0;
      const today = new Date();
      const summary = [];
      for (let i = 0; i < days; i++) {
        const d = new Date(today);
        d.setUTCDate(d.getUTCDate() - i);
        const dayStr = d.toISOString().slice(0, 10);
        const key = `day:${dayStr}`;
        const record = await env.BUDGET.get(key, { type: 'json' });
        const r = record || { calls: 0, in: 0, out: 0 };
        const costUsd =
          (r.in / 1_000_000) * INPUT_USD_PER_MTOK +
          (r.out / 1_000_000) * OUTPUT_USD_PER_MTOK;
        summary.push({
          day: dayStr,
          calls: r.calls,
          inputTokens: r.in,
          outputTokens: r.out,
          costUsd: Math.round(costUsd * 10000) / 10000,
        });
      }
      const totals = summary.reduce(
        (acc, d) => ({
          calls: acc.calls + d.calls,
          inputTokens: acc.inputTokens + d.inputTokens,
          outputTokens: acc.outputTokens + d.outputTokens,
          costUsd:
            Math.round((acc.costUsd + d.costUsd) * 10000) / 10000,
        }),
        { calls: 0, inputTokens: 0, outputTokens: 0, costUsd: 0 },
      );
      return jsonResponse({ days, summary, totals }, 200);
    }

    if (request.method !== 'POST' || url.pathname !== '/messages') {
      return jsonResponse({ error: 'Not found' }, 404);
    }

    // Shared-secret auth.
    const secret = request.headers.get('x-app-secret');
    if (!env.APP_SECRET || !secret || secret !== env.APP_SECRET) {
      return jsonResponse({ error: 'Forbidden' }, 403);
    }

    if (!env.ANTHROPIC_API_KEY) {
      return jsonResponse(
        { error: 'Worker misconfigured: ANTHROPIC_API_KEY missing' },
        500,
      );
    }

    const callType = request.headers.get('x-call-type') || 'unknown';
    const now = new Date();
    const dayKey = utcDayKey(now);
    const cap = Number(env.MAX_CALLS_PER_DAY) || DEFAULT_MAX_CALLS_PER_DAY;

    // Read today's aggregate so we can enforce the circuit breaker. Skipped
    // entirely when KV isn't bound, so the worker keeps working pre-setup.
    let dayRecord = { calls: 0, in: 0, out: 0 };
    if (env.BUDGET) {
      const existing = await env.BUDGET.get(dayKey, { type: 'json' });
      if (existing) dayRecord = existing;
      if (dayRecord.calls >= cap) {
        console.log(
          JSON.stringify({
            event: 'budget_cap_hit',
            day: dayKey,
            calls: dayRecord.calls,
            cap,
          }),
        );
        return jsonResponse(
          {
            error:
              'Daily request cap reached. Resets at 00:00 UTC. If you are seeing this in normal use, raise MAX_CALLS_PER_DAY.',
          },
          429,
        );
      }
    }

    let body;
    try {
      body = await request.text();
    } catch (e) {
      return jsonResponse({ error: 'Invalid request body' }, 400);
    }

    // Forward to Anthropic. We don't parse or modify the request JSON — the
    // app already knows the Anthropic schema, the Worker is just a credential
    // injection layer.
    const upstream = await fetch(ANTHROPIC_ENDPOINT, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-api-key': env.ANTHROPIC_API_KEY,
        'anthropic-version': ANTHROPIC_VERSION,
      },
      body,
    });

    const upstreamBody = await upstream.text();

    // Best-effort usage extraction for cost telemetry. Never let logging break
    // the proxied response.
    let inputTokens = 0;
    let outputTokens = 0;
    try {
      const parsed = JSON.parse(upstreamBody);
      if (parsed && parsed.usage) {
        inputTokens = parsed.usage.input_tokens || 0;
        outputTokens = parsed.usage.output_tokens || 0;
      }
    } catch (e) {
      // Non-JSON or error body: tokens stay 0, still logged below.
    }

    console.log(
      JSON.stringify({
        event: 'api_call',
        callType,
        status: upstream.status,
        inputTokens,
        outputTokens,
        ts: now.toISOString(),
      }),
    );

    // Update the daily aggregate after responding (non-blocking). Read-modify
    // -write isn't atomic, so counts can be slightly off under concurrency —
    // fine for a beta-scale safety net, not for billing.
    if (env.BUDGET) {
      const updated = {
        calls: dayRecord.calls + 1,
        in: dayRecord.in + inputTokens,
        out: dayRecord.out + outputTokens,
      };
      ctx.waitUntil(
        env.BUDGET.put(dayKey, JSON.stringify(updated), {
          expirationTtl: DAY_RECORD_TTL_SECONDS,
        }),
      );
    }

    return new Response(upstreamBody, {
      status: upstream.status,
      headers: {
        'content-type':
          upstream.headers.get('content-type') ?? 'application/json',
      },
    });
  },
};
