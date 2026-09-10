import {
  initializeApp,
  getApps,
  App,
  applicationDefault,
  cert,
} from "firebase-admin/app";
import { getAuth, Auth } from "firebase-admin/auth";
import { createRequire } from "node:module";

const projectId = process.env.FIREBASE_PROJECT_ID ?? "loyola-app-803a6";

function loadServiceAccount() {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT;

  if (raw) {
    try {
      return JSON.parse(raw);
    } catch {
      throw new Error(
        "FIREBASE_SERVICE_ACCOUNT is not valid JSON. " +
          "Paste the contents of your Firebase service-account JSON as a single value.",
      );
    }
  }

  const file = process.env.GOOGLE_APPLICATION_CREDENTIALS;

  if (file) {
    try {
      const require = createRequire(import.meta.url);

      return JSON.parse(require(file));
    } catch {
      // Fall through to applicationDefault below.
    }
  }

  return null;
}

function createFirebaseApp(): App {
  const existing = getApps()[0];

  if (existing) {
    return existing;
  }

  const serviceAccount = loadServiceAccount();

  return initializeApp({
    projectId,
    credential: serviceAccount ? cert(serviceAccount) : applicationDefault(),
  });
}

let cachedAuth: Auth | null = null;

export async function getFirebaseAuth(): Promise<Auth> {
  if (!cachedAuth) {
    cachedAuth = getAuth(createFirebaseApp());
  }

  return cachedAuth;
}