import "dotenv/config";
import fs from "node:fs";
import { createPrivateKey } from "node:crypto";

import { SignJWT } from "jose";
import { getFirebaseAuth } from "../src/config/firebase.js";
import { connectMongo } from "../src/config/mongo.js";

const BACKEND_URL = process.env.BACKEND_URL ?? "http://localhost:5000";
const WEB_API_KEY = process.env.FIREBASE_WEB_API_KEY;
const SA_PATH = process.env.GOOGLE_APPLICATION_CREDENTIALS;

if (!WEB_API_KEY) {
  console.error(
    "FIREBASE_WEB_API_KEY is required — add it to backend/.env (Firebase Console → Project settings → Web API key).",
  );
  process.exit(1);
}

if (!SA_PATH) {
  console.error(
    "GOOGLE_APPLICATION_CREDENTIALS is required in backend/.env (points at the service-account JSON).",
  );
  process.exit(1);
}

const testUid = `test-login-${Date.now()}`;
const testEmail = `login-test-${testUid}@example.com`;
const testName = "Login Test User";
const AUDIENCE =
  "https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit";

async function mintCustomToken(): Promise<string> {
  const sa = JSON.parse(fs.readFileSync(SA_PATH, "utf8"));
  const key = createPrivateKey(sa.private_key);
  const nowSec = Math.floor(Date.now() / 1000);

  return new SignJWT({ uid: testUid })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(sa.client_email)
    .setSubject(sa.client_email)
    .setAudience(AUDIENCE)
    .setIssuedAt(nowSec)
    .setExpirationTime(nowSec + 3600)
    .sign(key);
}

async function exchangeForIdToken(): Promise<{ idToken: string }> {
  const customToken = await mintCustomToken();

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
    throw new Error(`signInWithCustomToken failed (${res.status}): ${JSON.stringify(body)}`);
  }

  return { idToken: body.idToken };
}

try {
  await connectMongo();

  console.log(`\n→ Creating Firebase user ${testUid} (local RS256 custom-token signing)…`);

  await exchangeForIdToken();

  const auth = await getFirebaseAuth();
  await auth.setCustomUserClaims(testUid, { isE2ETest: true });
  await auth.updateUser(testUid, {
    email: testEmail,
    displayName: testName,
  });

  const { idToken } = await exchangeForIdToken();

  console.log(`→ POST ${BACKEND_URL}/api/v1/auth/google`);

  const loginRes = await fetch(`${BACKEND_URL}/api/v1/auth/google`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ idToken }),
  });

  const loginBody: any = await loginRes.json();

  if (!loginRes.ok || !loginBody.authentication?.token) {
    console.error(`\n✗ LOGIN FAILED (${loginRes.status})`);
    console.error(JSON.stringify(loginBody, null, 2));
    process.exit(1);
  }

  const { user, authentication } = loginBody;

  console.log(
    `✓ Login succeeded (${loginRes.status}) — user "${user.name}" ${user.email}`,
  );
  console.log(`  googleId: ${user.googleId}`);
  console.log(`  erpLinked: ${user.erpLinked}`);
  console.log(`  expiresAt: ${authentication.expiresAt} (7-day JWT session)`);

  const token = authentication.token as string;

  console.log(`\n→ GET ${BACKEND_URL}/api/v1/schedules (with session token)`);

  const schedRes = await fetch(`${BACKEND_URL}/api/v1/schedules`, {
    headers: { Authorization: `Bearer ${token}` },
  });

  const schedBody: any = await schedRes.json();

  if (schedRes.ok) {
    console.log(
      `✓ Authenticated API call works (${schedRes.status}) — ${schedBody.data?.length ?? 0} schedule(s)`,
    );
  } else {
    console.error(`✗ Authenticated API call failed (${schedRes.status})`);
    console.error(JSON.stringify(schedBody, null, 2));
    process.exit(1);
  }

  const cleanupAuth = await getFirebaseAuth();
  await cleanupAuth.deleteUser(testUid).catch(() => {});

  console.log("\nAll login checks passed.");
} catch (error: any) {
  console.error("\n✗ Test error:", error.message ?? error);
  const cleanupAuth = await getFirebaseAuth().catch(() => undefined);
  await cleanupAuth?.deleteUser(testUid).catch(() => {});
  process.exit(1);
}