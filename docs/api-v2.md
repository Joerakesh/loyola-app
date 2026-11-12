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
