// Aleph AI proxy: holds the OpenRouter key so it never ships inside the app.
// Also receives the opt-in anonymous usage counts at POST /event.
//
// The app sends the same chat-completion body it would send to OpenRouter,
// minus the key. This worker checks the model against an allowlist, caps the
// answer length, rate-limits per client IP, and forwards the call.
//
// Deploy: see proxy/README.md.

const OPENROUTER = 'https://openrouter.ai/api/v1/chat/completions';
const MAX_TOKENS = 4000;
const MAX_BODY_BYTES = 32 * 1024;

export default {
  async fetch(request, env) {
    if (request.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 });
    }

    if (new URL(request.url).pathname === '/event') return recordEvent(request, env);

    const ip = request.headers.get('CF-Connecting-IP') ?? 'unknown';
    const { success } = await env.LIMITER.limit({ key: ip });
    if (!success) return new Response('Too many requests', { status: 429 });

    const raw = await request.text();
    if (raw.length > MAX_BODY_BYTES) {
      return new Response('Request too large', { status: 413 });
    }

    let body;
    try {
      body = JSON.parse(raw);
    } catch {
      return new Response('Bad JSON', { status: 400 });
    }

    // Only the models the app is allowed to spend on. The paid model stays
    // out until purchases are verified server-side.
    const allowed = (env.ALLOWED_MODELS ?? '').split(',').map((m) => m.trim());
    if (!allowed.includes(body.model)) {
      return new Response('Model not allowed', { status: 403 });
    }
    body.max_tokens = Math.min(Number(body.max_tokens) || MAX_TOKENS, MAX_TOKENS);
    delete body.stream;

    const upstream = await fetch(OPENROUTER, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${env.OPENROUTER_API_KEY}`,
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://github.com/cYoren/Aleph',
        'X-Title': 'Aleph',
      },
      body: JSON.stringify(body),
    });

    return new Response(upstream.body, {
      status: upstream.status,
      headers: { 'Content-Type': 'application/json' },
    });
  },
};

// Opt-in usage counts. The app sends an event name, interface language,
// platform and whole days since install: no ids, no text, nothing
// about what was read. Days since install is what makes retention measurable
// without identifying anyone.
const EVENT_NAMES = new Set([
  'app_open',
  'daily_session_done',
  'path_started',
  'card_shared',
  'reminder_enabled',
  'first_verse_read',
  'first_review_done',
  'support_opened',
  'support_started',
  'support_completed',
  'support_failed',
  'onboarding_completed',
  'chapter_read',
  'first_value',
  'depth_layer_opened',
  'word_study_opened',
  'beginner_lesson_completed',
  'analytics_opt_out',
]);

// Every name above is a `UsageEvent.wireName` in lib/core/usage_events.dart.
// `test/proxy_event_names_test.dart` reads this file and fails if the two lists
// drift apart, because a name missing here is refused with 400 and the count is
// lost without a trace.

async function recordEvent(request, env) {
  let e;
  try {
    e = await request.json();
  } catch {
    return new Response('Bad JSON', { status: 400 });
  }
  if (!EVENT_NAMES.has(e.event)) return new Response('Unknown event', { status: 400 });
  const short = (v) => String(v ?? '').slice(0, 16);
  env.EVENTS.writeDataPoint({
    indexes: [e.event],
    blobs: [e.event, short(e.language), short(e.platform)],
    doubles: [Math.max(0, Math.min(Number(e.day) || 0, 10000))],
  });
  return new Response(null, { status: 204 });
}
