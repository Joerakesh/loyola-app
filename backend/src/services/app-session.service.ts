import { SignJWT, jwtVerify } from "jose";
import { PublicUser } from "../models/user.model.js";

const SESSION_TTL_DAYS = 7;

interface AppSessionPayload {
  sub: string;
  googleId: string;
  email: string;
}

export interface AppSession {
  token: string;
  expiresAt: number;
  payload: AppSessionPayload;
}

function getSecret(): Uint8Array {
  const secret = process.env.SESSION_SECRET;

  if (!secret) {
    throw new Error("SESSION_SECRET environment variable is not configured");
  }

  return new TextEncoder().encode(secret);
}

export class AppSessionService {
  async createSession(user: PublicUser): Promise<AppSession> {
    const expiresAt = Date.now() + SESSION_TTL_DAYS * 24 * 60 * 60 * 1000;

    const token = await new SignJWT({
      googleId: user.googleId,
      email: user.email,
    })
      .setProtectedHeader({ alg: "HS256" })
      .setSubject(user.id)
      .setIssuedAt()
      .setExpirationTime(Math.floor(expiresAt / 1000))
      .sign(getSecret());

    const payload = await this.verifySession(token);

    return { token, expiresAt, payload };
  }

  async verifySession(token: string): Promise<AppSessionPayload> {
    const { payload } = await jwtVerify(token, getSecret());

    if (!payload.sub || !payload.googleId || !payload.email) {
      throw new Error("Invalid session payload");
    }

    return {
      sub: payload.sub,
      googleId: payload.googleId as string,
      email: payload.email as string,
    };
  }
}

export const appSessionService = new AppSessionService();