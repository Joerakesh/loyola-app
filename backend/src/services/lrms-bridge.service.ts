import { LRMSClient, type LRMSRequester } from "../upstream/lrms.client.js";
import { credentialEncryptionService } from "./credential-encryption.service.js";
import { UserDocument } from "../models/user.model.js";
import { userRepository } from "../repositories/user.repository.js";
import { erpSessionRepository } from "../repositories/erp-session.repository.js";
import {
  DEFAULT_SESSION_TTL_MS,
  ErpSessionManager,
  type ErpUser,
} from "./erp-session.manager.js";

function toErpUser(user: UserDocument): ErpUser {
  const erp = user.erpCredential;

  if (!erp) {
    throw new Error("ERP credentials not linked");
  }

  return {
    id: user._id.toHexString(),
    registrationNumber: erp.registrationNumber,
  };
}

export class LRMSBridgeService {
  private readonly sessions: ErpSessionManager;

  constructor() {
    this.sessions = new ErpSessionManager({
      ttlMs: Number(process.env.LRMS_SESSION_TTL_MS) || DEFAULT_SESSION_TTL_MS,
      store: erpSessionRepository,
      login: (user) => this.loginFromStoredCredentials(user.id),
    });
  }

  /** Full ERP login with explicit credentials (used when linking an account). */
  async createClient(
    registrationNumber: string,
    password: string,
  ): Promise<LRMSClient> {
    const client = new LRMSClient();

    const loginPage = await client.getLoginPage();

    const result = await client.login(
      registrationNumber,
      password,
      loginPage.captcha,
    );

    if (!result || result.status !== "success") {
      throw new Error(result?.message ?? "LRMS login failed");
    }

    return client;
  }

  /**
   * A client for this user. Nothing is sent to the ERP until the first call, and
   * then a cached session is reused; a login only happens on a cache miss.
   */
  getClientForUser(user: UserDocument): LRMSRequester {
    return this.sessions.clientFor(toErpUser(user));
  }

  /** Drop the cached session, e.g. after ERP credentials change. */
  invalidate(userId: string) {
    return this.sessions.invalidate(userId);
  }

  private async loginFromStoredCredentials(userId: string) {
    // Reload the user so a relink between requests always uses fresh credentials.
    const user = await userRepository.findById(userId);
    const erp = user?.erpCredential;

    if (!erp) {
      throw new Error("ERP credentials not linked");
    }

    const password = credentialEncryptionService.decrypt(
      erp.passwordCiphertext,
    );

    return this.createClient(erp.registrationNumber, password);
  }
}

export const lrmsBridgeService = new LRMSBridgeService();

export async function assertErpLinked(userId: string) {
  const user = await userRepository.findById(userId);

  if (!user?.erpCredential) {
    throw new Error("ERP credentials not linked");
  }

  return user;
}
