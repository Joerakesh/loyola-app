import crypto from "node:crypto";
import { LRMSClient } from "../upstream/lrms.client.js";
import { lrmsSessionService } from "./lrms-session.service.js";

interface LoginResult {
  token: string;
  expiresAt: number;
  profile: unknown;
}

export class AuthService {
  async login(
    registrationNumber: string,
    password: string,
  ): Promise<LoginResult> {
    return this.authenticate(registrationNumber, password);
  }

  async refresh(
    registrationNumber: string,
    password: string,
  ): Promise<LoginResult> {
    return this.authenticate(registrationNumber, password);
  }

  private async authenticate(
    registrationNumber: string,
    password: string,
  ): Promise<LoginResult> {
    const client = new LRMSClient();

    // Get a fresh CAPTCHA
    const loginPage = await client.getLoginPage();

    // Login to LRMS
    const result = await client.login(
      registrationNumber,
      password,
      loginPage.captcha,
    );

    if (!result || result.status !== "success") {
      throw new Error(result?.message ?? "LRMS login failed");
    }

    // Generate our application's token
    const token = crypto.randomUUID();

    // Export the fresh LRMS session
    const session = await client.exportSession(registrationNumber);

    // Store the session in Redis
    await lrmsSessionService.createSession(token, session);

    // Our application token expires after 24 hours
    const expiresAt = Date.now() + 60 * 60 * 24 * 1000;

    return {
      token,
      expiresAt,
      profile: null,
    };
  }
}

export const authService = new AuthService();
