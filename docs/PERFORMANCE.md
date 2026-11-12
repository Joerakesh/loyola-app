# Performance notes

## Why requests were slow

Every ERP-backed API call used to perform a full LRMS login (load the login page,
read the captcha, post credentials) before the real request. The web dashboard
makes several such calls at once, so one page load could trigger many logins.

## What changed

| Change | Where | Effect |
| --- | --- | --- |
| Cached ERP session per user, shared by parallel requests, refreshed once when the ERP says it expired | `backend/src/services/erp-session.manager.ts` | A login happens only when no session is cached, instead of on every request |
| Session cookies stored (encrypted, TTL) in Mongo | `erp-session.repository.ts` | A cold serverless instance reuses a session instead of logging in |
| Per-user response cache (`X-Cache: HIT/MISS/BYPASS`), `?refresh=1` to bypass | `middleware/response-cache.middleware.ts`, `lib/erp-cache.ts` | Repeat visits skip the ERP completely |
| `GET /api/v1/home` | `controllers/home.controller.ts` | The dashboard makes one request instead of seven, and a failing section no longer blanks the page |
| Mongo indexes created at startup | `config/bootstrap.ts` | `ensureIndexes()` existed but was never called |
| Marks reuse the cached profile | `controllers/marks.controller.ts` | One ERP call instead of two |
| Vercel function region `bom1` | `vercel.json` | Close to the ERP and to an Atlas cluster in Mumbai |

Cache lifetimes are in `ERP_TTL_MS` (`lib/erp-cache.ts`). The ERP session idle
lifetime defaults to 15 minutes; override with `LRMS_SESSION_TTL_MS`.

## Deployment checklist

1. **Atlas region.** Put the MongoDB Atlas cluster in AWS Mumbai (`ap-south-1`).
   Moving an existing cluster means creating a new one and migrating the data.
2. **Vercel region.** `vercel.json` sets `bom1`. Confirm under Project Settings,
   Functions, that the region applies after the next deploy.
3. **Environment variables.** Add `CORS_ORIGINS` (comma-separated web origins) in
   production. Optional: `LRMS_SESSION_TTL_MS`, `MONGODB_MAX_POOL_SIZE` (default 5).
4. **Measure.** Check the `X-Cache` header and Vercel function durations before and
   after. Expect the first request after idle to be slower (login), and following
   requests to be much faster.

## Known limits

- The in-memory caches are per function instance. A different instance has its own
  cache, which costs one extra ERP call, never wrong data.
- After a student changes data inside the ERP, the app can show the old value until
  the cache expires or they pull to refresh (`?refresh=1`).
