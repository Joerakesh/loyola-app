import crypto from "node:crypto";

import { LRMSClient } from "../upstream/lrms.client.js";
import { lrmsSessionService } from "./lrms-session.service.js";

interface LoginResult {
  token: string;
  profile: unknown;
}

export class AuthService {
  async login(
    registrationNumber: string,
    password: string,
  ): Promise<LoginResult> {
    const client = new LRMSClient();

    // Fetch login page and obtain CAPTCHA.
    const loginPage = await client.getLoginPage();

    // Login using the automatically
    // obtained CAPTCHA.
    const result = await client.login(
      registrationNumber,
      password,
      loginPage.captcha,
    );

    if (!result || result.status !== "success") {
      throw new Error(result?.message ?? "LRMS login failed");
    }

    // Create our application token.
    const token = crypto.randomUUID();

    // Convert LRMSClient into serializable
    // session state.
    const session = await client.exportSession(registrationNumber);

    // Store session state.
    lrmsSessionService.createSession(token, session);

    return {
      token,
      profile: null,
    };
  }
}

export const authService = new AuthService();
