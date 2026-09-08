import { LRMSClient } from "../upstream/lrms.client.js";
import { credentialEncryptionService } from "./credential-encryption.service.js";
import { UserDocument } from "../models/user.model.js";
import { userRepository } from "../repositories/user.repository.js";

export class LRMSBridgeService {
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
}

export const lrmsBridgeService = new LRMSBridgeService();

export async function assertErpLinked(userId: string) {
  const user = await userRepository.findById(userId);

  if (!user?.erpCredential) {
    throw new Error("ERP credentials not linked");
  }

  return user;
}