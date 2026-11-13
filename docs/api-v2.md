# Portal API v2

The v2 portal API reads data from the authenticated student's LRMS session. It does not use HAR-captured response values, cookies, or credentials. All routes below require the app's bearer session and a linked ERP account, except password sync, which verifies the supplied new password by logging in to LRMS.

## Routes
- `GET /api/v2` returns a public version and section index.
- `GET /api/v2/portal` returns all portal sections, keyed by section name under `data`.
- `GET /api/v2/portal/:section` returns one of `profile`, `dashboard`, `attendance`, `academics`, `fees`, or `registrations` directly under `data`.
- `GET /api/v2/platform/:collection` returns saved `assignments`, `announcements`, `schedules`, `reminders`, or `notifications` for the authenticated user.
- `POST /api/v2/portal/credentials` accepts `{ "password": "..." }` to verify and save a password already changed on LRMS.
- `PUT /api/v2/portal/password` accepts `{ "currentPassword": "...", "newPassword": "..." }` and changes the LRMS password.

## Sections
- `profile`: student profile and sidebar identity.
- `dashboard`: dashboard and attendance summary.
- `attendance`: summary, hourly records and subject-wise totals.
- `academics`: subjects and internal assessment marks.
- `fees`: payments, dues, challans, fee notices and registration/condonation status.
- `registrations`: semester, course, hall-ticket, assessment and club statuses.

## Authentication
Google and ERP are independent initial sign-in methods.

### Google sign-in
- `POST /api/v1/auth/google`
- Body: `{ "idToken": "<Firebase Google ID token>" }`

### Standalone ERP sign-in
- `POST /api/v1/auth/erp`
- Body: `{ "username": "<ERP registration number>", "password": "<LRMS password>" }` (`registrationNumber` may replace `username`).
- The backend verifies credentials against LRMS, finds the account by registration number or creates an ERP-only account, encrypts the password with `ERP_CREDENTIALS_ENCRYPTION_KEY`, and issues the app bearer session.
- Invalid credentials return generic HTTP 401. Existing auth rate limit: 30 requests/minute/client IP.

### Link ERP to a Google-first account
- `POST /api/v1/auth/bind-erp` (authenticated)
- Body: `{ "registrationNumber": "...", "password": "..." }`
- Verifies ERP credentials before linking to the authenticated Google account.

### Link Google to an ERP-first account
- `POST /api/v1/auth/bind-google` (authenticated with the ERP-first app bearer token)
- Body: `{ "idToken": "<fresh Firebase Google ID token>" }`
- Verifies the Firebase token and links its Google UID and email to the current ERP-backed user.
- Requires an existing ERP credential on the authenticated account.
- Returns HTTP 409 if the Google UID or email belongs to another app account. No automatic account merge is performed.
- On success, returns the updated public user. The current bearer token remains valid.

Use `Authorization: Bearer <token>` for protected routes. ERP credentials are encrypted at rest (AES-256-GCM). Configure `ERP_CREDENTIALS_ENCRYPTION_KEY` and `SESSION_SECRET` in backend environment variables. Never log request bodies, passwords, tokens or decrypted credentials.

## Account and data ownership
- The app user ID is derived from the verified bearer token, never from a client-supplied student ID.
- Google UID, primary email and ERP registration number must each belong to at most one app user.
- Conflicts return HTTP 409; accounts are never silently merged based only on matching email text.
- Portal routes use the authenticated user's linked ERP credentials and LRMS session. Never expose raw credentials, cookies or session state.
