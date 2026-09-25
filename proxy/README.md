# Aleph AI proxy and usage counts

A Cloudflare Worker that holds the OpenRouter key, so release builds no longer
need `--dart-define=OPENROUTER_API_KEY` (a key compiled into the app can be
pulled out of the binary by anyone).

## Deploy (once)

```bash
cd proxy
npx wrangler login
npx wrangler secret put OPENROUTER_API_KEY   # paste the key
npx wrangler deploy                          # prints https://aleph-ai-proxy.<you>.workers.dev
```

## Point the app at it

Build with the worker URL instead of the key:

```bash
flutter build ios --release --dart-define=ALEPH_AI_PROXY=https://aleph-ai-proxy.<you>.workers.dev
```

For CI, add the URL as a repository variable `ALEPH_AI_PROXY` and pass it the
same way in the workflow's `flutter build` step.

## Notes

- `ALLOWED_MODELS` in `wrangler.toml` must list every model the app requests;
  anything else is refused with 403. The paid model is deliberately absent
  until purchases are verified on the server.
- Rate limit: 10 requests per minute per IP. Tune in `wrangler.toml`.

## Usage counts

`POST /event` records the opt-in anonymous counts (Settings > Share anonymous
usage counts, off by default) into the `aleph_events` Analytics Engine dataset.
Each point is an event name, interface language, platform and days
since install. There is no install id, so nothing links two events together.

Day-7 retention, roughly: installs are `app_open` points with `double1 = 0`;
returning users on day 7 are `app_open` points with `double1 = 7`.

```sql
SELECT double1 AS day, count() AS opens
FROM aleph_events WHERE blob1 = 'app_open' AND double1 IN (0, 1, 7, 30)
GROUP BY day ORDER BY day
```
