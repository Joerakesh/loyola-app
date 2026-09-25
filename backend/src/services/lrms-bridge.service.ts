import { LRMSClient } from "../upstream/lrms.client.js";
import { credentialEncryptionService } from "./credential-encryption.service.js";
import { UserDocument } from "../models/user.model.js";
import { userRepository } from "../repositories/user.repository.js";
import { lrmsSessionCacheService } from "./lrms-session-cache.service.js";

export class LRMSBridgeService {
  /**
   * Authenticated LRMS client for raw credentials. Sessions are cached and
   * reused, so linking/validation flows don't spam the college server.
   */
  async createClient(
    registrationNumber: string,
    password: string,
  ): Promise<LRMSClient> {
    return lrmsSessionCacheService.getClient(registrationNumber, password);
  }

  async createClientForUser(user: UserDocument): Promise<LRMSClient> {
    const erp = user.erpCredential;

    if (!erp) {
      throw new Error("ERP credentials not linked");
    }

    const password = credentialEncryptionService.decrypt(
      erp.passwordCiphertext,
    );

    return this.createClient(erp.registrationNumber, password);
  }

  /**
   * Drops the cached LRMS session for a user — used when a cached session is
   * found to be dead so the next call logs in fresh.
   */
  async invalidateSessionForUser(user: UserDocument): Promise<void> {
    if (user.erpCredential) {
      lrmsSessionCacheService.evict(user.erpCredential.registrationNumber);
    }
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