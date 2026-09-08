import { firebaseAuth } from "../config/firebase.js";

export interface GoogleProfile {
  googleId: string;
  email: string;
  name: string;
  avatarUrl: string;
}

export class GoogleAuthService {
  async verifyIdToken(idToken: string): Promise<GoogleProfile> {
    const decoded = await firebaseAuth.verifyIdToken(idToken);

    return {
      googleId: decoded.uid,
      email: decoded.email ?? "",
      name: decoded.name ?? "",
      avatarUrl: decoded.picture ?? "",
    };
  }
}

export const googleAuthService = new GoogleAuthService();