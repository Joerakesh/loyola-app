# Loyola System Architecture v2

## Current baseline
- Flutter mobile client; Node.js/TypeScript/Express backend; MongoDB.
- Firebase-verified Google sign-in and independent ERP sign-in.
- LRMS bridge with encrypted ERP credentials and cached ERP sessions.
- Portal data: profile, dashboard, attendance, academics, fees and registrations.
- Platform collections: assignments, announcements, schedules, reminders and notifications.

Keep the backend as a modular monolith. Do not introduce microservices until measured operational needs justify them.

## Target architecture
```text
Flutter (secure token storage, local cache)
  -> HTTPS Express API (auth, validation, rate limits)
  -> Modular services (Identity, Portal, Academic, Campus, Fees, AI)
  -> Repositories/adapters (MongoDB, LRMS bridge, college site, AI provider)
  -> Operations (logs, metrics, health checks, backups)
```

## Identity and ownership
One canonical app user represents one student. Google UID, primary email and ERP registration number are unique identities attached to that user.

- Resolve user identity only from the verified bearer session.
- Never accept a client-supplied student ID to select academic records.
- Link an identity only after proving control of the existing session and the new identity.
- Never silently merge accounts because email strings match.
- Return conflict when an identity is already owned by another app user.

The API now supports both directions: Google-first users link ERP via `POST /api/v1/auth/bind-erp`; ERP-first users link Google via `POST /api/v1/auth/bind-google`.

## Security requirements
- Keep Firebase credentials, session/encryption secrets and future AI API keys on the backend.
- Encrypt ERP passwords and LRMS session cookies at rest; never log credentials or tokens.
- Use HTTPS and secure platform token storage.
- Implement short-lived access tokens, rotating refresh tokens, per-device sessions and server-side revocation before claiming revocable logout.
- Validate all write requests, rate-limit authentication and AI calls, and test object-level authorization for every student-owned resource.
- Redact personal identifiers and secrets from logs.

## LRMS and data freshness
All LRMS requests go through the existing LRMS bridge/session manager. Do not scrape from each mobile screen independently. Cached data may remain available during upstream outages, but responses must distinguish fresh, stale and unavailable data. Expose source and last-sync metadata only when it is actually known. Add background sync only with a scheduler/queue compatible with the deployment runtime; serverless in-process timers are not reliable.

## Student AI assistant (planned)
Build a read-only assistant using explicit backend tools, never unrestricted MongoDB or LRMS access. Initial tools: attendance summary, subject attendance, deterministic attendance allowance calculation, subjects and internal marks. Assessments, fees and announcements can follow when their sources are reliable.

Every tool derives the student from the authenticated request. Calculations and policy logic run in backend code, not in the model. Answers must state source and last-sync time, and admit when data is missing, stale or ambiguous. Never invent attendance policy, assessment dates or timetable entries. Keep provider keys server-side; add per-user quotas, timeouts, output limits and privacy-aware conversation retention.

## Operations
Add structured/redacted logs, request correlation IDs, liveness/readiness checks, error reporting, metrics for LRMS latency/cache freshness/auth failures, automated backups and restore drills. CI should run typecheck, tests and production build before deployment.

## Delivery phases
1. Identity/access: bidirectional linking, duplicate/race tests, cross-student authorization audit, revocable sessions.
2. Reliability: request schemas, central errors, data provenance, LRMS failure handling, monitoring and backup verification.
3. UX: dashboard hierarchy, offline cache, explicit stale states and source-backed alerts.
4. AI: read-only academic tools, deterministic calculations, provenance, privacy and cost controls.

## Acceptance criteria
- Both sign-in paths can link the second identity without creating a second user.
- A Google UID, email or ERP registration number cannot belong to two users.
- Cross-student data access fails closed.
- LRMS failure does not erase last-known-good cached data.
- Academic cache freshness is visible.
- AI only answers from authorized tools and reports missing/stale data.
- Typecheck, tests and build pass in CI before deployment.

## Not in scope yet
Microservices, unrestricted AI database access, invented academic policy, serverless in-process background timers, or automatic merging of duplicate accounts.
