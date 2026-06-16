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

// Safety system-prompt block prepended to every Anthropic call (Task #88.2,
// liability guardrails). Server-side so the client cannot bypass it: the
// Worker injects this BEFORE the client-supplied system prompt regardless
// of what the binary in the App Store says. Stays short (under the 1024-
// token cache-block minimum, so we don't bother marking it cacheable);
// covers role + escalation pattern + blocklist-recommendation veto.
const SAFETY_BLOCK_DE = `WICHTIG, sicherheitsrelevante Grundregeln (überlagern alles andere):
- Du gibst allgemeine Ernährungs- und Wohlfühl-Information, KEINEN medizinischen Rat, KEINE Diagnose, KEINE individuellen Dosierungs-Empfehlungen.
- Bei medizinisch heiklen Themen (Blutungen, starke Schmerzen, Medikamente, Vorerkrankungen, Symptome, Mangelverdacht mit Beschwerden) verweise an die Hebamme oder Ärztin und gib KEINE eigene Empfehlung.
- Bei akuten Notfall-Anzeichen (starke Blutung, vorzeitige Wehen, kein Kindsbewegen, Ohnmacht, Sehstörungen) sage klar: das ist ein Notfall, sofort 112 oder die Klinik anrufen. KEIN Ernährungstipp.
- Empfehle NIEMALS Lebensmittel, die auf der Food-Safety-Blocklist der App stehen (Alkohol, rohe Tierprodukte, Großraubfisch in der Schwangerschaft, etc.). Warnungen dazu sind erlaubt, Empfehlungen nicht.
- Bei Unsicherheit immer die vorsichtigere Antwort.`;

const SAFETY_BLOCK_EN = `IMPORTANT safety ground rules (override everything else):
- You provide general nutrition and wellness information, NOT medical advice, NO diagnosis, NO individual dosing recommendations.
- For medically sensitive topics (bleeding, severe pain, medications, pre-existing conditions, symptoms, suspected deficiency with complaints) refer to the midwife or doctor and give NO recommendation yourself.
- For acute emergency signs (heavy bleeding, preterm labour, no baby movement, fainting, vision changes) state clearly: this is an emergency, call your local emergency services or the clinic immediately. NO nutrition tip.
- NEVER recommend foods on the app's food-safety blocklist (alcohol, raw animal products, large predatory fish in pregnancy, etc.). Warnings about them are allowed, recommendations are not.
- When in doubt, choose the more cautious answer.`;

// Re-exported for the standalone unit tests; the Worker itself only uses
// the default export below.
export {
  injectSafetyBlock,
  SAFETY_BLOCK_DE,
  SAFETY_BLOCK_EN,
  pseudonymizeUser,
  AUDIT_EVENT,
  classifyInput,
  EMERGENCY_KEYWORDS,
  ESCALATION_KEYWORDS,
  EMERGENCY_RESPONSES,
  ESCALATION_RESPONSES,
  classifyOutput,
  BLOCKLIST_KEYWORDS,
  RECOMMENDATION_PHRASES_DE,
  RECOMMENDATION_PHRASES_EN,
  BLOCKED_RESPONSES,
};

function utcDayKey(now) {
  return `day:${now.toISOString().slice(0, 10)}`; // day:YYYY-MM-DD
}

// Audit-log event types for safety-relevant happenings (Task #88.7). The
// emit sites for the Block/Escalation/Emergency events are wired up by
// the input classifier (#88.3) and output post-check (#88.4); this Worker
// already publishes the helper + event names so those tasks can drop
// emit calls in without touching the logging contract.
const AUDIT_EVENT = Object.freeze({
  EMERGENCY: 'audit_emergency',     // input matched a 112-tier keyword
  ESCALATION: 'audit_escalation',   // input matched a medical-handoff keyword
  BLOCKED_OUTPUT: 'audit_blocked',  // model output recommended a blocklist item
  // Pure usage telemetry, no safety signal — kept named for grep-ability.
  API_CALL: 'api_call',
});

// Pseudonymise the client's install-id into a stable per-install hex hash
// that cannot be reversed to the install-id without APP_SECRET (the salt).
// We deliberately do NOT log raw install-ids: in a breach the salted hash
// only correlates one user's events to each other, never to a real device.
// Truncated to 16 hex chars (≈ 2^64 search space) — plenty for any beta
// scale, half the byte cost of the full SHA-256.
async function pseudonymizeUser(installId, secret) {
  if (!installId || !secret) return 'anon';
  const data = new TextEncoder().encode(`${installId}:${secret}`);
  const hashBuf = await crypto.subtle.digest('SHA-256', data);
  const hex = Array.from(new Uint8Array(hashBuf))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
  return hex.slice(0, 16);
}

// Emits a structured JSON line for safety-relevant events. By contract:
// NEVER include raw user input, raw model output, or any free-text field
// the model produced. Only the rule-ID that fired, the call type, the
// pseudonymised user hash, and an ISO timestamp. This is the data set
// we are willing to disclose if subpoenaed; everything else stays in
// the user's local Hive.
function auditEvent({ type, ruleId, callType, userHash, ts, extra }) {
  // eslint-disable-next-line no-console
  console.log(
    JSON.stringify({
      event: type,
      ruleId: ruleId || null,
      callType: callType || 'unknown',
      userHash: userHash || 'anon',
      ts: ts || new Date().toISOString(),
      ...(extra || {}),
    }),
  );
}

// Emergency + escalation keyword lists for the input pre-classifier
// (Task #88.3). SYNC NOTE: these MUST stay aligned with the
// inputTriggers section of assets/safety-rules.json (which the Flutter
// client loads). The lists are short and stable so we accept a manual-
// sync workflow rather than bundling JSON into the Worker.
//
// Semantics:
// - emergency = acute danger (heavy bleeding, preterm labour, no baby
//   movement, fainting, vision changes). Worker returns the canned
//   emergency response with NO Anthropic call.
// - escalation = medical handoff (medication, gestational diabetes,
//   mastitis, postpartum depression, ...). Worker returns the canned
//   escalation response with NO Anthropic call.
// Emergency takes precedence when both stages would match.
const EMERGENCY_KEYWORDS = Object.freeze({
  de: [
    'starke blutung', 'blute stark', 'stark am bluten',
    'vorzeitige wehen', 'frühzeitige wehen',
    'kein kindsbewegen', 'kindsbewegungen weg', 'spürt kind nicht',
    'ohnmächtig', 'umgekippt', 'kollaps',
    'sehstörungen', 'sehe doppelt', 'verschwommen sehen', 'schwarze punkte vor augen',
    'starke kopfschmerzen mit sehstörungen', 'preeklampsie', 'präeklampsie',
    'starke bauchschmerzen', 'heftige bauchschmerzen',
    'fruchtwasser geht ab', 'blasensprung',
    'atemnot', 'bekomme keine luft', 'brustschmerzen',
  ],
  en: [
    'heavy bleeding', 'bleeding heavily', 'lots of blood',
    'strong bleeding', 'severe bleeding', 'much blood',
    'preterm labour', 'preterm labor', 'early contractions',
    'no baby movement', 'baby not moving', "baby isn't moving", 'baby is not moving',
    'fainting', 'passed out', 'blacked out',
    'blurred vision', 'double vision', 'spots in vision', 'vision changes',
    'severe headache with vision', 'preeclampsia',
    'severe abdominal pain', 'intense abdominal pain',
    'water broke', 'amniotic fluid',
    'shortness of breath', "can't breathe", 'chest pain',
  ],
});

const ESCALATION_KEYWORDS = Object.freeze({
  de: [
    'medikament', 'tablette einnehmen', 'antibiotikum', 'antibiotika',
    'schwangerschaftsdiabetes', 'gestationsdiabetes',
    'bluthochdruck', 'hypertonie',
    'mastitis', 'milchstau', 'brustentzündung',
    'wochenbettdepression', 'postpartale depression', 'postnatale depression',
    'eisenmangel', 'vitamin d mangel', 'schilddrüsenproblem',
    'diät machen', 'abnehmen wollen',
    'extreme erschöpfung', 'chronisch müde',
  ],
  en: [
    'medication', 'taking medicine', 'antibiotic', 'antibiotics',
    'gestational diabetes', 'type 2 diabetes',
    'high blood pressure', 'hypertension',
    'mastitis', 'blocked duct', 'engorgement',
    'postpartum depression', 'postnatal depression',
    'iron deficiency', 'vitamin d deficiency', 'thyroid issue',
    'go on a diet', 'want to lose weight',
    'extreme exhaustion', 'chronically tired',
  ],
});

const EMERGENCY_RESPONSES = Object.freeze({
  de: 'Das klingt nach einem Notfall. Ruf bitte sofort die [112](tel:112) oder deine Klinik/Hebamme an. NourishMe ist nicht für Notfälle gedacht.',
  en: 'This sounds like an emergency. Please call [112](tel:112) (EU emergency number) or your clinic/midwife immediately. NourishMe is not designed for emergencies.',
});

const ESCALATION_RESPONSES = Object.freeze({
  de: 'Das gehört zu deiner Hebamme oder Ärztin, nicht zu mir. Ich gebe nur allgemeine Ernährungs-Info und kann deine konkrete Situation nicht einschätzen. Bitte sprich das mit ihr durch.',
  en: 'This is something for your midwife or doctor to discuss with you, not me. I give general nutrition info only and can\'t assess your specific situation. Please talk it through with them.',
});

// Walks the Anthropic request body looking for the user's most recent
// message text and classifies it against the emergency/escalation lists.
// Returns { classification, ruleId, response } where classification is
// 'emergency', 'escalation', or 'normal'. Defensive: any unexpected
// shape (non-string content, missing messages) yields 'normal' so the
// Worker never errors out the request just to classify it.
function classifyInput(parsedBody, locale) {
  const text = extractLatestUserText(parsedBody);
  if (!text) return { classification: 'normal' };
  const lower = text.toLowerCase();
  const emKeywords = EMERGENCY_KEYWORDS[locale] || EMERGENCY_KEYWORDS.en;
  const emHit = emKeywords.find((k) => lower.includes(k));
  if (emHit) {
    return {
      classification: 'emergency',
      ruleId: emHit,
      response: EMERGENCY_RESPONSES[locale] || EMERGENCY_RESPONSES.en,
    };
  }
  const esKeywords = ESCALATION_KEYWORDS[locale] || ESCALATION_KEYWORDS.en;
  const esHit = esKeywords.find((k) => lower.includes(k));
  if (esHit) {
    return {
      classification: 'escalation',
      ruleId: esHit,
      response: ESCALATION_RESPONSES[locale] || ESCALATION_RESPONSES.en,
    };
  }
  return { classification: 'normal' };
}

// Pulls plain text out of the LAST message in the body (the freshest
// user input). Handles both shapes the client sends:
//   - {role:'user', content:'string'} (chat & safety paths)
//   - {role:'user', content:[{type:'text', text:'...'}, ...]} (parse path with photo)
// We deliberately only inspect the LAST message: classifying every
// historical message in a chat would re-fire on the user's own past
// reactions to escalation responses ("you told me to see a doctor about
// my mastitis last week").
function extractLatestUserText(parsedBody) {
  const messages = Array.isArray(parsedBody?.messages) ? parsedBody.messages : [];
  for (let i = messages.length - 1; i >= 0; i--) {
    const m = messages[i];
    if (m?.role !== 'user') continue;
    const content = m.content;
    if (typeof content === 'string') return content;
    if (Array.isArray(content)) {
      const parts = [];
      for (const item of content) {
        if (item?.type === 'text' && typeof item.text === 'string') {
          parts.push(item.text);
        }
      }
      return parts.join(' ');
    }
    return '';
  }
  return '';
}

// Curated subset of high-value blocklist keywords for the output post-check
// (Task #88.4 Tier 1). SYNC NOTE: this is intentionally a subset of the
// full assets/safety-rules.json keyword universe - we only post-check items
// the model is realistically tempted to recommend or downplay. Obscure
// compounds (wildschweininnereien, bismarckhering) get adequate coverage
// from the input-side rule engine plus the system-prompt safety block; the
// post-check is the third line of defence and stays surgical.
const BLOCKLIST_KEYWORDS = Object.freeze([
  // Alcohol - classic LLM walk-back risk
  'alkohol', 'alcohol', 'wein', 'wine', 'rotwein', 'weißwein',
  'bier', 'beer', 'sekt', 'prosecco', 'champagner', 'champagne',
  'cocktail', 'rum', 'wodka', 'vodka', 'whisky', 'whiskey', 'gin',
  'tequila', 'aperol', 'sangria',
  // Raw animal classics - frequent recommendation traps
  'tatar', 'mett', 'carpaccio', 'rohmilch', 'raw milk', 'salami',
  'camembert', 'brie', 'gorgonzola', 'roquefort', 'weichkäse',
  'soft cheese', 'sushi', 'sashimi', 'räucherlachs', 'smoked salmon',
  'graved', 'gravlax', 'parmaschinken', 'prosciutto', 'serrano',
  'bresaola', 'tiramisu', 'hollandaise',
  // Mercury fish
  'thunfisch', 'tuna', 'schwertfisch', 'swordfish', 'hai', 'shark',
  'marlin',
  // Liver / vitamin A
  'leber', 'liver', 'foie gras',
  // Algae
  'spirulina', 'chlorella', 'algen', 'algae', 'seaweed', 'nori',
  // Quinine
  'tonic water', 'bitter lemon', 'chinin', 'quinine',
  // Wild boar (rare)
  'wildschwein', 'wild boar',
]);

// Recommendation/endorsement phrases (DE + EN). Detected as substrings
// within the SAME sentence as a blocklist keyword - that's the signature
// of "the model endorsed a forbidden item" as opposed to "the model
// warned about it" ("vermeide Tatar" must NOT trip the block).
const RECOMMENDATION_PHRASES_DE = Object.freeze([
  'ist okay', 'ist ok', 'ist in ordnung', 'in ordnung',
  'kannst du essen', 'kannst essen', 'darfst du essen', 'darfst essen',
  'ist unbedenklich', 'unbedenklich', 'ist sicher',
  'spricht nichts dagegen', 'kein problem', 'geht klar',
  'vertretbar', 'akzeptabel', 'unproblematisch',
  'gelegentlich ist', 'in maßen',
  'empfehlenswert', 'empfehle ich', 'kann ich empfehlen',
]);

const RECOMMENDATION_PHRASES_EN = Object.freeze([
  'is okay', 'is ok', 'is fine', 'is safe', 'is acceptable',
  'you can eat', 'you can have', 'feel free to', 'go ahead',
  'no problem', 'nothing wrong',
  'in moderation', 'occasionally is', 'is recommended', 'i recommend',
]);

const BLOCKED_RESPONSES = Object.freeze({
  de: 'Dazu gebe ich dir lieber keinen Rat. Sprich das mit deiner Hebamme oder Ärztin durch.',
  en: 'I would rather not give you advice on that. Please talk it through with your midwife or doctor.',
});

// Scan a model-generated text against the blocklist + recommendation
// phrases. Returns { classification, ruleId, response } where
// classification is 'blocked' (replace the output) or 'normal'
// (pass through unchanged). Both DE+EN phrase sets are always
// checked because models sometimes mix languages mid-reply.
function classifyOutput(modelText, locale) {
  if (!modelText || typeof modelText !== 'string') {
    return { classification: 'normal' };
  }
  const lower = modelText.toLowerCase();
  // Sentence-ish split: periods, exclamation, question mark, newline,
  // semicolon. Keeps the rec-phrase and blocklist hit scoped to a
  // single sentence so "vermeide Tatar. Stattdessen Lachs ist okay"
  // does not block (Tatar is in a warning sentence, "ist okay"
  // belongs to a different sentence about a different food).
  const sentences = lower.split(/[.!?\n;]+/);
  const primary = locale === 'de'
      ? RECOMMENDATION_PHRASES_DE
      : RECOMMENDATION_PHRASES_EN;
  const secondary = locale === 'de'
      ? RECOMMENDATION_PHRASES_EN
      : RECOMMENDATION_PHRASES_DE;
  for (const sentence of sentences) {
    const blockHit = BLOCKLIST_KEYWORDS.find((k) => sentence.includes(k));
    if (!blockHit) continue;
    const recHit =
        primary.find((p) => sentence.includes(p)) ||
        secondary.find((p) => sentence.includes(p));
    if (!recHit) continue;
    return {
      classification: 'blocked',
      ruleId: `${blockHit}+${recHit}`,
      response: BLOCKED_RESPONSES[locale] || BLOCKED_RESPONSES.en,
    };
  }
  return { classification: 'normal' };
}

// Inject the server-side safety block at the start of the request's `system`
// field. Handles both shapes the app sends today:
//   - string: convert to array [{safety}, {client_text}]
//   - array (cache_control on a downstream item): prepend [{safety}, ...rest]
// Preserves any cache_control markers the client placed - the breakpoint
// just shifts one index, which Anthropic treats identically.
// On a body the client sent without a `system` field at all (shouldn't
// happen with the current client, but a defensive default), we still inject
// the safety block as the only entry so the model gets the safety floor.
function injectSafetyBlock(parsedBody, locale) {
  const safetyText = locale === 'de' ? SAFETY_BLOCK_DE : SAFETY_BLOCK_EN;
  const safetyItem = { type: 'text', text: safetyText };
  const existing = parsedBody.system;
  if (existing == null) {
    parsedBody.system = [safetyItem];
  } else if (typeof existing === 'string') {
    parsedBody.system = [safetyItem, { type: 'text', text: existing }];
  } else if (Array.isArray(existing)) {
    parsedBody.system = [safetyItem, ...existing];
  } else {
    // Unknown shape (object?) - wrap defensively, don't drop the safety floor.
    parsedBody.system = [safetyItem, existing];
  }
  return parsedBody;
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

    // Per-install pseudonymous hash for audit logs (Task #88.7). The
    // client sends its anonymous analytics install-id as x-install-id;
    // we salt it with APP_SECRET and truncate. Logs only ever see the
    // hash, never the raw install-id or anything user-typed. Falls back
    // to 'anon' if the header is missing (old clients pre-#88.7 build)
    // so logging keeps working during the rollout window.
    const installId = request.headers.get('x-install-id') || '';
    const userHash = await pseudonymizeUser(installId, env.APP_SECRET || '');

    // Read today's aggregate so we can enforce the circuit breaker. Skipped
    // entirely when KV isn't bound, so the worker keeps working pre-setup.
    let dayRecord = { calls: 0, in: 0, out: 0 };
    if (env.BUDGET) {
      const existing = await env.BUDGET.get(dayKey, { type: 'json' });
      if (existing) dayRecord = existing;
      if (dayRecord.calls >= cap) {
        auditEvent({
          type: 'budget_cap_hit',
          callType,
          userHash,
          ts: now.toISOString(),
          extra: { day: dayKey, calls: dayRecord.calls, cap },
        });
        return jsonResponse(
          {
            error:
              'Daily request cap reached. Resets at 00:00 UTC. If you are seeing this in normal use, raise MAX_CALLS_PER_DAY.',
          },
          429,
        );
      }
    }

    let rawBody;
    try {
      rawBody = await request.text();
    } catch (e) {
      return jsonResponse({ error: 'Invalid request body' }, 400);
    }
    let parsedBody;
    try {
      parsedBody = JSON.parse(rawBody);
    } catch (e) {
      return jsonResponse({ error: 'Request body must be JSON' }, 400);
    }
    if (!parsedBody || typeof parsedBody !== 'object') {
      return jsonResponse(
        { error: 'Request body must be a JSON object' },
        400,
      );
    }

    const locale =
      (request.headers.get('x-locale') || '').toLowerCase().startsWith('de')
        ? 'de'
        : 'en';

    // Input pre-classifier (Task #88.3). Defense in depth: the Flutter
    // client also runs this check and short-circuits there, but we
    // re-run on the server so a tampered / stale / non-Flutter client
    // still cannot pull LLM advice for emergency or escalation inputs.
    // On match we synthesise an Anthropic-shaped response with our
    // canned text and skip the upstream call entirely (and skip the
    // billing/token telemetry).
    const inputClass = classifyInput(parsedBody, locale);
    if (inputClass.classification !== 'normal') {
      auditEvent({
        type:
          inputClass.classification === 'emergency'
            ? AUDIT_EVENT.EMERGENCY
            : AUDIT_EVENT.ESCALATION,
        ruleId: inputClass.ruleId,
        callType,
        userHash,
        ts: now.toISOString(),
      });
      return jsonResponse(
        {
          id: `synth_${inputClass.classification}_${now.getTime()}`,
          type: 'message',
          role: 'assistant',
          model: 'nourishme-safety-synth',
          content: [{ type: 'text', text: inputClass.response }],
          stop_reason: 'end_turn',
          usage: { input_tokens: 0, output_tokens: 0 },
          // Worker-only extension: lets the client render the bubble
          // in the escalation/emergency style instead of as a normal
          // coach reply. Anthropic ignores unknown top-level fields,
          // so the client always sees this field whether the response
          // came from the synth path or upstream.
          nourishme_response_type: inputClass.classification,
        },
        200,
      );
    }

    // Inject the server-side safety block (Task #88.2). Runs BEFORE the
    // Anthropic call so the safety rules sit at the top of the system
    // prompt the model sees, regardless of what the client binary
    // composed.
    parsedBody = injectSafetyBlock(parsedBody, locale);
    const body = JSON.stringify(parsedBody);

    // Forward to Anthropic.
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

    // Best-effort usage extraction for cost telemetry + output post-check
    // (Task #88.4). The text content goes into classifyOutput; usage
    // numbers go into the audit log + KV aggregate. Both wrapped in try
    // so any unexpected upstream shape (HTML error page, partial JSON)
    // just degrades gracefully to "log zero, pass through".
    let inputTokens = 0;
    let outputTokens = 0;
    let contentText = '';
    try {
      const parsed = JSON.parse(upstreamBody);
      if (parsed && parsed.usage) {
        inputTokens = parsed.usage.input_tokens || 0;
        outputTokens = parsed.usage.output_tokens || 0;
      }
      if (Array.isArray(parsed?.content)) {
        contentText = parsed.content
          .map((c) => (c && typeof c.text === 'string' ? c.text : ''))
          .join('\n');
      }
    } catch (e) {
      // Non-JSON or error body: stays empty, post-check + token-log skipped.
    }

    // Output post-check (Tier 1 regex). If the model recommended a
    // blocklist item, swap the response for the synthesised blocked
    // fallback BEFORE returning to the client. Emergency/escalation
    // synth responses (from input-classifier) are already short-
    // circuited above and never reach this point.
    let responseBody = upstreamBody;
    let postCheckStatus = upstream.status;
    let postCheckBlocked = false;
    if (upstream.status === 200 && contentText) {
      const outputCheck = classifyOutput(contentText, locale);
      if (outputCheck.classification === 'blocked') {
        postCheckBlocked = true;
        auditEvent({
          type: AUDIT_EVENT.BLOCKED_OUTPUT,
          ruleId: outputCheck.ruleId,
          callType,
          userHash,
          ts: now.toISOString(),
        });
        responseBody = JSON.stringify({
          id: `synth_blocked_${now.getTime()}`,
          type: 'message',
          role: 'assistant',
          model: 'nourishme-safety-synth',
          content: [{ type: 'text', text: outputCheck.response }],
          stop_reason: 'end_turn',
          usage: { input_tokens: 0, output_tokens: 0 },
          nourishme_response_type: 'blocked',
        });
        postCheckStatus = 200;
      }
    }

    auditEvent({
      type: AUDIT_EVENT.API_CALL,
      callType,
      userHash,
      ts: now.toISOString(),
      extra: {
        status: upstream.status,
        inputTokens,
        outputTokens,
        // Marks calls where the post-check intercepted the model output
        // so /budget/summary can later show "X% of replies blocked".
        postCheckBlocked,
      },
    });

    // Update the daily aggregate after responding (non-blocking). Read-modify
    // -write isn't atomic, so counts can be slightly off under concurrency,
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

    return new Response(responseBody, {
      status: postCheckStatus,
      headers: {
        'content-type':
          upstream.headers.get('content-type') ?? 'application/json',
      },
    });
  },
};
