import { initializeApp, getApps, App, applicationDefault } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";

const projectId = process.env.FIREBASE_PROJECT_ID ?? "loyola-app-803a6";

function createFirebaseApp(): App {
  const existing = getApps()[0];

  if (existing) {
    return existing;
  }

  return initializeApp({
    projectId,
    credential: applicationDefault(),
  });
}

export const firebaseApp = createFirebaseApp();
export const firebaseAuth = getAuth(firebaseApp);