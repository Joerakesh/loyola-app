import "dotenv/config";
import fs from "node:fs";
import { createPrivateKey } from "node:crypto";

import { SignJWT } from "jose";
import { getFirebaseAuth } from "../src/config/firebase.js";
import { connectMongo, getDb } from "../src/config/mongo.js";
import { userRepository } from "../src/repositories/user.repository.js";
import { appSessionService } from "../src/services/app-session.service.js";

/**
 * End-to-end API smoke test.
 *
 * Logs in as a throwaway user, then hits every endpoint exposed by the
 * backend: health, auth, ERP-backed endpoints, the 5 platform CRUD
 * resources (schedules / announcements / assignments / reminders / notifications),
 * the public college-website announcements scraper (GET /api/v1/announcements),
 * and the academic calendar (GET /api/v1/calendar).
 *
 * Two auth modes:
 *   1. Full Firebase login (default when FIREBASE_WEB_API_KEY is set):
 *      mints a custom token from the service account, exchanges it for an ID
 *      token, and calls POST /api/v1/auth/google — exercising that endpoint too.
 *   2. Local session (when FIREBASE_WEB_API_KEY is missing): creates a
 *      throwaway user in Mongo and mints a session token locally with the app's
 *      SESSION_SECRET, so every other endpoint can still be verified.
 *
 * Env:
 *   Required (Firebase mode):  FIREBASE_WEB_API_KEY + FIREBASE_SERVICE_ACCOUNT
 *                              (or GOOGLE_APPLICATION_CREDENTIALS path)
 *   Required (local mode):     SESSION_SECRET, MONGODB_URI (already in .env)
 *   Optional:                  BACKEND_URL (default http://localhost:5000)
 *                              TEST_ERP_REG_NO / TEST_ERP_PASSWORD / TEST_ERP_EMAIL
 *                              TEST_TIMEOUT_MS (default 20000)
 *
 * Run: npm run test:endpoints
 */

const BACKEND_URL = (process.env.BACKEND_URL ?? "http://localhost:5000").replace(/\/+$/, "");
const WEB_API_KEY = process.env.FIREBASE_WEB_API_KEY;
const SERVICE_ACCOUNT_RAW = process.env.FIREBASE_SERVICE_ACCOUNT;
const SA_PATH = process.env.GOOGLE_APPLICATION_CREDENTIALS;
const SESSION_SECRET = process.env.SESSION_SECRET;
const TEST_ERP_REG_NO = process.env.TEST_ERP_REG_NO;
const TEST_ERP_PASSWORD = process.env.TEST_ERP_PASSWORD;
const TEST_ERP_EMAIL = process.env.TEST_ERP_EMAIL;
const TEST_TIMEOUT_MS = Number(process.env.TEST_TIMEOUT_MS ?? 20000);

// ---------------------------------------------------------------------------
// Config / guards
// ---------------------------------------------------------------------------

if (!WEB_API_KEY && !SESSION_SECRET) {
  console.error(
    "Nothing to authenticate with — set one of:\n" +
      "  - FIREBASE_WEB_API_KEY  (full Firebase login flow)\n" +
      "  - SESSION_SECRET        (local session minting; uses the same secret as the backend)",
  );
  process.exit(1);
}

if (WEB_API_KEY && !(SERVICE_ACCOUNT_RAW || SA_PATH)) {
  console.error(
    "FIREBASE_WEB_API_KEY is set but no service account was found.\n" +
      "  Set FIREBASE_SERVICE_ACCOUNT (JSON) or GOOGLE_APPLICATION_CREDENTIALS (file path).",
  );
  process.exit(1);
}

/** Load the Firebase service-account JSON (inline env var or file path). */
function loadServiceAccount(): Record<string, string> {
  if (SERVICE_ACCOUNT_RAW) {
    try {
      return JSON.parse(SERVICE_ACCOUNT_RAW);
    } catch {
      throw new Error("FIREBASE_SERVICE_ACCOUNT is not valid JSON.");
    }
  }
  return JSON.parse(fs.readFileSync(SA_PATH!, "utf8"));
}

const AUDIENCE =
  "https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit";

const testUid = `test-endpoints-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
const testEmail = `endpoints-test-${testUid}@example.com`;

// ---------------------------------------------------------------------------
// HTTP helpers
// ---------------------------------------------------------------------------

interface RequestOptions {
  method: string;
  path: string;
  token?: string | null;
  body?: unknown;
  timeoutMs?: number;
}

interface HttpResponse {
  status: number;
  body: any;
  ms: number;
}

async function call(opts: RequestOptions): Promise<HttpResponse> {
  const timeoutMs = opts.timeoutMs ?? TEST_TIMEOUT_MS;

  for (let attempt = 0; ; attempt++) {
    const abort = new AbortController();
    const timer = setTimeout(() => abort.abort(), timeoutMs);
    const started = Date.now();

    try {
      const headers: Record<string, string> = {};
      if (opts.body !== undefined) headers["Content-Type"] = "application/json";
      if (opts.token) headers.Authorization = `Bearer ${opts.token}`;

      const res = await fetch(`${BACKEND_URL}${opts.path}`, {
        method: opts.method,
        headers,
        body: opts.body !== undefined ? JSON.stringify(opts.body) : undefined,
        signal: abort.signal,
      });

      const text = await res.text();
      let body: any = text;
      try {
        body = JSON.parse(text);
      } catch {
        /* non-JSON response */
      }

      // Backend applies an express-rate-limit of 100 req/min. On a 429, wait
      // for the window to reset and retry once before giving up.
      if (res.status === 429 && attempt < 1) {
        console.log(
          `      (429 rate-limit on ${opts.method} ${opts.path} — waiting 61s for the window to reset…)`,
        );
        await new Promise((resolve) => setTimeout(resolve, 61_000));
        continue;
      }

      return { status: res.status, body, ms: Date.now() - started };
    } finally {
      clearTimeout(timer);
    }
  }
}

// ---------------------------------------------------------------------------
// Result tracking
// ---------------------------------------------------------------------------

interface TestResult {
  group: string;
  method: string;
  path: string;
  status: number;
  expected: number[];
  pass: boolean;
  note?: string;
  ms: number;
}

const results: TestResult[] = [];
let passed = 0;
let failed = 0;
let skipped = 0;

function record(
  group: string,
  method: string,
  path: string,
  res: HttpResponse,
  expected: number[],
  note?: string,
): void {
  const pass = expected.includes(res.status);

  if (pass) passed++;
  else failed++;

  results.push({
    group,
    method,
    path,
    status: res.status,
    expected,
    pass,
    note,
    ms: res.ms,
  });

  const mark = pass ? "✓" : "✗";

  console.log(
    `  ${mark} ${method.padEnd(6)} ${path.padEnd(46)} ${String(res.status).padEnd(4)} (expected ${expected.join("|")}) ${res.ms}ms${note ? ` — ${note}` : ""}`,
  );
}

function recordSkip(group: string, method: string, path: string, note: string): void {
  skipped++;
  results.push({
    group,
    method,
    path,
    status: 0,
    expected: [],
    pass: true,
    note,
    ms: 0,
  });

  console.log(`  ⏭  SKIP ${method.padEnd(6)} ${path.padEnd(46)} ${note}`);
}

function logResponse(res: HttpResponse, maxLen = 500): void {
  const preview = JSON.stringify(res.body);
  console.log(
    `      ↳ ${preview.length > maxLen ? preview.slice(0, maxLen) + "…" : preview}`,
  );
}

// ---------------------------------------------------------------------------
// Test suites
// ---------------------------------------------------------------------------

async function testHealth(): Promise<void> {
  console.log("\n── Health ─────────────────────────────────────────────────");
  const res = await call({ method: "GET", path: "/api/health" });
  record("health", "GET", "/api/health", res, [200]);
}

async function testUnauthenticatedRejected(): Promise<void> {
  console.log("\n── Auth guard (no token) ──────────────────────────────────");
  const res = await call({ method: "GET", path: "/api/v1/schedules" });
  record("auth-guard", "GET", "/api/v1/schedules (no token)", res, [401]);
  const boot = await call({ method: "GET", path: "/api/v1/bootstrap" });
  record("auth-guard", "GET", "/api/v1/bootstrap (no token)", boot, [401]);
  const bad = await call({
    method: "POST",
    path: "/api/v1/auth/google",
    body: {},
  });
  record("auth-guard", "POST", "/api/v1/auth/google (empty body)", bad, [400]);
}

async function testAuth(token: string): Promise<void> {
  console.log("\n── Auth ───────────────────────────────────────────────────");

  const me = await call({ method: "GET", path: "/api/v1/auth/google/me", token });
  record("auth", "GET", "/api/v1/auth/google/me", me, [200]);

  const refresh = await call({ method: "POST", path: "/api/v1/auth/refresh", token });
  record(
    "auth",
    "POST",
    "/api/v1/auth/refresh",
    refresh,
    [200],
    "returns a fresh session token",
  );

  const bindEmailBad = await call({
    method: "POST",
    path: "/api/v1/auth/bind-email",
    token,
    body: {},
  });
  record(
    "auth",
    "POST",
    "/api/v1/auth/bind-email (missing email)",
    bindEmailBad,
    [400],
  );

  const bindEmail = await call({
    method: "POST",
    path: "/api/v1/auth/bind-email",
    token,
    body: { email: `link-${testUid}@example.com` },
  });
  record("auth", "POST", "/api/v1/auth/bind-email", bindEmail, [200]);

  const bindErpBad = await call({
    method: "POST",
    path: "/api/v1/auth/bind-erp",
    token,
    body: {},
  });
  record(
    "auth",
    "POST",
    "/api/v1/auth/bind-erp (missing fields)",
    bindErpBad,
    [400],
  );

  if (TEST_ERP_REG_NO && TEST_ERP_PASSWORD) {
    console.log("      (TEST_ERP creds found — attempting live ERP bind)");
    const body: Record<string, string> = {
      registrationNumber: TEST_ERP_REG_NO,
      password: TEST_ERP_PASSWORD,
    };
    if (TEST_ERP_EMAIL) body.email = TEST_ERP_EMAIL;
    const bindErp = await call({
      method: "POST",
      path: "/api/v1/auth/bind-erp",
      token,
      body,
      timeoutMs: 60_000,
    });
    record(
      "auth",
      "POST",
      "/api/v1/auth/bind-erp",
      bindErp,
      [200, 400],
      "200=bound, 400=LRMS login rejected (bad captcha/creds)",
    );
    if (bindErp.status !== 200) logResponse(bindErp);
  } else {
    console.log(
      "      (set TEST_ERP_REG_NO / TEST_ERP_PASSWORD to exercise live ERP bind)",
    );
  }

  const unbind = await call({ method: "POST", path: "/api/v1/auth/unbind-erp", token });
  record("auth", "POST", "/api/v1/auth/unbind-erp", unbind, [200]);
}

async function testErpEndpoints(token: string): Promise<void> {
  console.log("\n── ERP-backed data (needs account linked to LRMS) ─────────");
  console.log(
    "     Without TEST_ERP_REG_NO/PASSWORD these expect 403 (auth verified, ERP not linked).",
  );

  const endpoints: Array<[string, string]> = [
    ["GET", "/api/v1/attendance/summary"],
    ["GET", "/api/v1/attendance/hourly"],
    ["GET", "/api/v1/marks/internal"],
    ["GET", "/api/v1/subjects"],
    ["GET", "/api/v1/student/profile"],
    ["GET", "/api/v1/dashboard"],
    ["GET", "/api/v1/bootstrap"],
  ];

  for (const [method, path] of endpoints) {
    const res = await call({ method, path, token });
    const expected = TEST_ERP_REG_NO ? [200, 502] : [403];
    const note = TEST_ERP_REG_NO
      ? "200=data, 502=LRMS unreachable"
      : "403 expected (ERP not linked)";
    record("erp", method, path, res, expected, note);
    if (!expected.includes(res.status)) logResponse(res);
  }
}

const PLATFORM_RESOURCES: Array<{
  resource: string;
  basePath?: string;
  createBody: Record<string, unknown>;
  updateBody: Record<string, unknown>;
  actions: Array<"read" | "done">;
}> = [
  {
    resource: "schedules",
    createBody: {
      title: "Test Schedule",
      dayOfWeek: "Monday",
      startTime: "09:00",
      endTime: "10:00",
      location: "Test Hall",
    },
    updateBody: { title: "Test Schedule (updated)", location: "Room 42" },
    actions: [],
  },
  {
    resource: "announcements",
    // `/api/v1/announcements` is public (college website scraper), so the
    // authenticated user-CRUD lives at this namespaced path.
    basePath: "/api/v1/user/announcements",
    createBody: {
      title: "Test Announcement",
      body: "This is a test announcement body.",
      pinned: false,
    },
    updateBody: { title: "Test Announcement (updated)", pinned: true },
    actions: ["read"],
  },
  {
    resource: "assignments",
    createBody: {
      title: "Test Assignment",
      description: "Submit before class.",
      subject: "Mathematics",
      dueDate: new Date(Date.now() + 7 * 86_400_000).toISOString(),
    },
    updateBody: { title: "Test Assignment (updated)" },
    actions: ["done"],
  },
  {
    resource: "reminders",
    createBody: {
      title: "Test Reminder",
      body: "Remind me to hydrate.",
      remindAt: new Date(Date.now() + 3 * 86_400_000).toISOString(),
    },
    updateBody: { title: "Test Reminder (updated)" },
    actions: ["read", "done"],
  },
  {
    resource: "notifications",
    createBody: {
      type: "info",
      title: "Test Notification",
      body: "Hello from the test runner.",
      data: { test: true },
    },
    updateBody: { title: "Test Notification (updated)" },
    actions: ["read"],
  },
];

async function testPlatformResource(
  token: string,
  cfg: (typeof PLATFORM_RESOURCES)[number],
): Promise<void> {
  const { resource, basePath, createBody, updateBody, actions } = cfg;
  const group = `platform/${resource}`;
  const base = basePath ?? `/api/v1/${resource}`;
  const dash = "-".repeat(Math.max(2, 48 - resource.length));

  console.log(`\n── Platform: ${resource} ${dash}`);

  const listEmpty = await call({ method: "GET", path: base, token });
  record(group, "GET", base, listEmpty, [200]);

  const created = await call({
    method: "POST",
    path: base,
    token,
    body: createBody,
  });
  record(group, "POST", base, created, [201]);
  const id = created.body?.data?._id;

  if (!id) {
    logResponse(created);
    return; // can't run the rest without an id
  }

  const list = await call({ method: "GET", path: `${base}?limit=10`, token });
  record(group, "GET", `${base}?limit=10`, list, [200]);

  const got = await call({ method: "GET", path: `${base}/${id}`, token });
  record(group, "GET", `${base}/${id}`, got, [200]);

  const patched = await call({
    method: "PATCH",
    path: `${base}/${id}`,
    token,
    body: updateBody,
  });
  record(group, "PATCH", `${base}/${id}`, patched, [200]);

  for (const action of actions) {
    const res = await call({
      method: "POST",
      path: `${base}/${id}/${action}`,
      token,
    });
    record(group, "POST", `${base}/${id}/${action}`, res, [200]);
  }

  const bogus = await call({
    method: "GET",
    path: `${base}/000000000000000000000000`,
    token,
  });
  record(group, "GET", `${base}/000… (bogus id)`, bogus, [404, 400]);

  const deleted = await call({ method: "DELETE", path: `${base}/${id}`, token });
  record(group, "DELETE", `${base}/${id}`, deleted, [200]);

  const gone = await call({ method: "GET", path: `${base}/${id}`, token });
  record(group, "GET", `${base}/${id} (after delete)`, gone, [404, 400]);
}

async function testPlatform(token: string): Promise<void> {
  for (const cfg of PLATFORM_RESOURCES) {
    await testPlatformResource(token, cfg);
  }
}

async function testWebsite(): Promise<void> {
  console.log("\n── College website (public scraper) ───────────────────────");
  console.log(
    "     Public endpoint — fetches announcements from loyolacollege.edu without auth.",
  );

  const res = await call({
    method: "GET",
    path: "/api/v1/announcements",
    timeoutMs: 30_000,
  });
  record(
    "website",
    "GET",
    "/api/v1/announcements",
    res,
    [200],
    "live scrape of loyolacollege.edu (no auth)",
  );

  if (res.status !== 200) {
    logResponse(res);
    return;
  }

  const items = res.body?.data;

  if (!Array.isArray(items) || items.length === 0) {
    failed++;
    results.push({
      group: "website",
      method: "GET",
      path: "/api/v1/announcements",
      status: res.status,
      expected: [200],
      pass: false,
      note: "data should be a non-empty array of announcements",
      ms: res.ms,
    });
    logResponse(res, 900);
    return;
  }

  const first = items[0];
  if (!first?.title || !first?.url) {
    failed++;
    results.push({
      group: "website",
      method: "GET",
      path: "/api/v1/announcements",
      status: res.status,
      expected: [200],
      pass: false,
      note: "announcement missing title/url",
      ms: res.ms,
    });
    logResponse(res, 900);
    return;
  }

  console.log(
    `      ↳ ${items.length} announcement(s) — first: ${JSON.stringify(first.title).slice(0, 90)}`,
  );
  console.log(`        attachment: ${first.attachment ? "yes (" + first.attachment.type + ")" : "no"}`);
}

async function testCalendar(): Promise<void> {
  console.log("\n── Academic calendar (public, Mongo-backed) ────────────────");

  const now = new Date();
  const monthParam = `${now.getUTCFullYear()}-${String(now.getUTCMonth() + 1).padStart(2, "0")}`;

  // Month query — triggers an on-demand sync of that month on first run.
  const monthRes = await call({
    method: "GET",
    path: `/api/v1/calendar?month=${monthParam}`,
    timeoutMs: 60_000,
  });
  record(
    "calendar",
    "GET",
    `/api/v1/calendar?month=${monthParam}`,
    monthRes,
    [200],
    "month query (lazy sync)",
  );

  const badMonth = await call({
    method: "GET",
    path: "/api/v1/calendar?month=2026-13",
    timeoutMs: 10_000,
  });
  record("calendar", "GET", "/api/v1/calendar?month=2026-13 (invalid)", badMonth, [400]);

  const badFrom = await call({
    method: "GET",
    path: "/api/v1/calendar?from=not-a-date",
    timeoutMs: 10_000,
  });
  record("calendar", "GET", "/api/v1/calendar?from=not-a-date (invalid)", badFrom, [400]);

  if (monthRes.status === 200 && Array.isArray(monthRes.body?.data)) {
    const first = monthRes.body.data[0];
    console.log(
      `      ↳ ${monthRes.body.data.length} day(s) with events/day orders` +
        (first
          ? ` — e.g. ${first.date}${first.dayOrder ? ` (${first.dayOrder})` : ""}: ${String(first.event).slice(0, 70)}`
          : ""),
    );
  }

  // Range query within the same month (should be served from Mongo, no refetch).
  const rangeRes = await call({
    method: "GET",
    path: `/api/v1/calendar?from=${monthParam}-01&to=${monthParam}-28`,
    timeoutMs: 15_000,
  });
  record(
    "calendar",
    "GET",
    `/api/v1/calendar?from=${monthParam}-01&to=${monthParam}-28`,
    rangeRes,
    [200],
    "range query",
  );

  // Forced refresh re-fetches the month from the college site right away.
  const refreshRes = await call({
    method: "GET",
    path: `/api/v1/calendar?month=${monthParam}&refresh=1`,
    timeoutMs: 60_000,
  });
  record(
    "calendar",
    "GET",
    `/api/v1/calendar?month=${monthParam}&refresh=1`,
    refreshRes,
    [200],
    "forced refresh",
  );
}

async function testLogout(token: string): Promise<void> {
  console.log("\n── Logout ──────────────────────────────────────────────────");
  const res = await call({ method: "POST", path: "/api/v1/auth/logout", token });
  record("auth", "POST", "/api/v1/auth/logout", res, [200]);
}

// ---------------------------------------------------------------------------
// Summary
// ---------------------------------------------------------------------------

function printSummary(): void {
  const total = passed + failed + skipped;

  console.log("\n═══════════════════════════════════════════════════════════");
  console.log(
    `  SUMMARY  ${passed} passed · ${failed} failed · ${skipped} skipped · ${total} total`,
  );
  console.log("═══════════════════════════════════════════════════════════");

  if (failed > 0) {
    console.log("\nFailures:");
    for (const r of results.filter((r) => !r.pass)) {
      console.log(
        `  ✗ ${r.method} ${r.path} → got ${r.status}, expected ${r.expected.join("|")}`,
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Auth bootstrap + cleanup
// ---------------------------------------------------------------------------

let localUserId: string | null = null;

async function authenticate(): Promise<string> {
  if (WEB_API_KEY) {
    console.log(`\nCreating Firebase test user ${testUid} …`);

    async function exchangeForIdToken(): Promise<string> {
      const sa = loadServiceAccount();
      const nowSec = Math.floor(Date.now() / 1000);
      const customToken = await new SignJWT({ uid: testUid })
        .setProtectedHeader({ alg: "RS256", typ: "JWT" })
        .setIssuer(sa.client_email)
        .setSubject(sa.client_email)
        .setAudience(AUDIENCE)
        .setIssuedAt(nowSec)
        .setExpirationTime(nowSec + 3600)
        .sign(createPrivateKey(sa.private_key));

      const res = await fetch(
        `https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${WEB_API_KEY}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ token: customToken, returnSecureToken: true }),
        },
      );

      const body: any = await res.json();

      if (!res.ok || !body.idToken) {
        throw new Error(
          `signInWithCustomToken failed (${res.status}): ${JSON.stringify(body)}`,
        );
      }

      return body.idToken as string;
    }

    await exchangeForIdToken();

    const auth = await getFirebaseAuth();
    await auth.setCustomUserClaims(testUid, { isE2ETest: true });
    await auth.updateUser(testUid, {
      email: testEmail,
      displayName: "Endpoints Test User",
    });

    const idToken = await exchangeForIdToken();

    console.log("Logging in via POST /api/v1/auth/google …");
    const login = await call({
      method: "POST",
      path: "/api/v1/auth/google",
      body: { idToken },
    });
    record("auth", "POST", "/api/v1/auth/google", login, [200]);

    if (login.status !== 200) {
      logResponse(login);
      throw new Error("Login failed — cannot continue");
    }

    return login.body.authentication.token as string;
  }

  // Local fallback: no Firebase Web API key → create a Mongo user and mint a
  // session token with the same SESSION_SECRET the backend uses.
  console.log(
    `\nFIREBASE_WEB_API_KEY not set — using local session minting (Mongo + SESSION_SECRET).`,
  );
  recordSkip(
    "auth",
    "POST",
    "/api/v1/auth/google",
    "needs FIREBASE_WEB_API_KEY (set it to exercise the real login flow)",
  );

  const user = await userRepository.create({
    googleId: testUid,
    email: testEmail,
    name: "Endpoints Test User",
  });
  localUserId = user._id.toHexString();

  const session = await appSessionService.createSession(
    userRepository.toPublicUser(user),
  );

  return session.token;
}

async function cleanup(): Promise<void> {
  try {
    // Platform docs left behind (best-effort, should already be deleted via API)
    if (localUserId) {
      const db = await getDb();
      for (const collection of [
        "schedules",
        "announcements",
        "assignments",
        "reminders",
        "notifications",
      ]) {
        await db
          .collection(collection)
          .deleteMany({ userId: localUserId } as any)
          .catch(() => {});
      }
      await db
        .collection("users")
        .deleteOne({ email: testEmail })
        .catch(() => {});
    }

    if (WEB_API_KEY) {
      const auth = await getFirebaseAuth();
      await auth.deleteUser(testUid).catch(() => {});
      const db = await getDb();
      await db.collection("users").deleteOne({ email: testEmail }).catch(() => {});
    }
  } catch {
    /* cleanup is best-effort */
  }
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main(): Promise<number> {
  await connectMongo();

  console.log(`\nBackend under test: ${BACKEND_URL}`);

  const token = await authenticate();

  await testHealth();
  await testUnauthenticatedRejected();
  await testAuth(token);
  await testErpEndpoints(token);
  await testWebsite();
  await testCalendar();
  await testPlatform(token);
  await testLogout(token);

  printSummary();

  return failed > 0 ? 1 : 0;
}

let exitCode = 0;

try {
  exitCode = await main();
} catch (error: any) {
  console.error("\n✗ Test run failed:", error.message ?? error);
  exitCode = 1;
} finally {
  await cleanup();
  // Exit explicitly — open Mongo/HTTP keep-alive connections would otherwise
  // keep the Node process running after the tests are done.
  process.exit(exitCode);
}