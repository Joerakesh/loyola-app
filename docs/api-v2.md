# Portal API v2

The v2 portal API reads data from the authenticated student's LRMS session. It does not use HAR-captured response values, cookies, or credentials. All routes below require the app's bearer session and a linked ERP account, except password sync, which verifies the supplied new password by logging in to LRMS.

## Routes

- `GET /api/v2` returns a public version and section index.
- `GET /api/v2/portal` returns all portal sections, keyed by section name under `data`.
- `GET /api/v2/portal/:section` returns one of `profile`, `dashboard`, `attendance`, `academics`, `fees`, or `registrations` directly under `data` (without an extra section-name wrapper).
- `GET /api/v2/platform/:collection` returns saved `assignments`, `announcements`, `schedules`, `reminders`, or `notifications` for the authenticated user.
- `POST /api/v2/portal/credentials` accepts `{ "password": "..." }` to verify and save a password already changed on the official LRMS site.
- `PUT /api/v2/portal/password` accepts `{ "currentPassword": "...", "newPassword": "..." }` and changes the LRMS password through its `changepassword.jsp` endpoint. The saved encrypted credential is replaced only after LRMS reports success.

Successful read responses have `{ "status": "success", "data": { ... }, "unavailable": [] }`. In the all-sections response, an unavailable section is `null` and its safe error message is listed in `unavailable`; successful sections remain available.

## Sections and LRMS sources

- `profile`: full student profile and sidebar identity.
- `dashboard`: student dashboard and attendance summary.
- `attendance`: attendance summary, hour-by-hour records, and subject-wise totals.
- `academics`: subjects and internal assessment marks.
- `fees`: payment rows, due rows, challan configurations, fee notices, department, registration-fee status, and condonation status.
- `registrations`: semester, course, hall-ticket, assessment, and club registration statuses.

The implementation follows the request methods and form field names observed in `lrms.loyolacollege.edu.har`, including `studentid`, `registerno`, `currentPassword`, and `newPassword`. It does not include values from that capture.

## Authentication

The app supports two independent initial sign-in methods. Students may use Google or their Loyola LRMS credentials; Google is not required for ERP sign-in.

### Google sign-in

- `POST /api/v1/auth/google`
- Body: `{ "idToken": "<Firebase Google ID token>" }`
- Verifies the Google identity and returns the Loyola app bearer session.

### Standalone ERP sign-in

- `POST /api/v1/auth/erp`
- Body: `{ "username": "<ERP registration number>", "password": "<LRMS password>" }`
- `registrationNumber` may be used instead of `username`.
- The backend opens the LRMS login page, obtains its current CAPTCHA value, and verifies the supplied credentials directly against LRMS.
- On successful verification, the backend finds the existing app account by ERP registration number or creates an ERP-only app account. It encrypts and stores the ERP password using `ERP_CREDENTIALS_ENCRYPTION_KEY`, then returns the same seven-day bearer-session format used by Google sign-in.
- Invalid credentials return HTTP 401 with a generic message. Credentials are never returned in the response.
- The endpoint is covered by the existing `/api/v1/auth` rate limit (30 requests per minute per client IP).

Example success response:

```json
{
  "status": "success",
  "user": {
    "id": "<app-user-id>",
    "name": "<registration-number>",
    "linkedEmails": [],
    "erpLinked": true
  },
  "authentication": {
    "token": "<bearer-session>",
    "tokenType": "Bearer",
    "expiresAt": 0
  }
}
```

Use the returned token as `Authorization: Bearer <token>` for protected routes, including Portal API v2. ERP-only users have no Google ID or email until they explicitly link a Google identity/email through a supported account-linking flow. Do not assume a Google account is present.

ERP credentials are verified before account creation/update and stored encrypted at rest (AES-256-GCM). Configure `ERP_CREDENTIALS_ENCRYPTION_KEY` and `SESSION_SECRET` in the backend environment. Never log request bodies, passwords, or decrypted credentials.

Existing Google sign-in and authenticated `POST /api/v1/auth/bind-erp` account-linking flows remain supported.
