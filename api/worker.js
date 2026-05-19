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
// Endpoints:
//   POST /messages   → forwards to api.anthropic.com/v1/messages
//   GET  /health     → simple liveness check (no auth)
//
// Deployment: see README.md in this folder.

const ANTHROPIC_ENDPOINT = 'https://api.anthropic.com/v1/messages';
const ANTHROPIC_VERSION = '2023-06-01';

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // Health check (unauthenticated).
    if (request.method === 'GET' && url.pathname === '/health') {
      return new Response(JSON.stringify({ status: 'ok' }), {
        headers: { 'content-type': 'application/json' },
      });
    }

    if (request.method !== 'POST' || url.pathname !== '/messages') {
      return new Response(
        JSON.stringify({ error: 'Not found' }),
        { status: 404, headers: { 'content-type': 'application/json' } },
      );
    }

    // Shared-secret auth.
    const secret = request.headers.get('x-app-secret');
    if (!env.APP_SECRET || !secret || secret !== env.APP_SECRET) {
      return new Response(
        JSON.stringify({ error: 'Forbidden' }),
        { status: 403, headers: { 'content-type': 'application/json' } },
      );
    }

    if (!env.ANTHROPIC_API_KEY) {
      return new Response(
        JSON.stringify({ error: 'Worker misconfigured: ANTHROPIC_API_KEY missing' }),
        { status: 500, headers: { 'content-type': 'application/json' } },
      );
    }

    let body;
    try {
      body = await request.text();
    } catch (e) {
      return new Response(
        JSON.stringify({ error: 'Invalid request body' }),
        { status: 400, headers: { 'content-type': 'application/json' } },
      );
    }

    // Forward to Anthropic. We don't parse or modify the JSON — the app
    // already knows the Anthropic schema, the Worker is just a credential
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
    return new Response(upstreamBody, {
      status: upstream.status,
      headers: {
        'content-type':
          upstream.headers.get('content-type') ?? 'application/json',
      },
    });
  },
};
