import { userRepository } from "../repositories/user.repository.js";
import { PublicUser } from "../models/user.model.js";
import { googleAuthService } from "./google-auth.service.js";
import { lrmsBridgeService } from "./lrms-bridge.service.js";
import { credentialEncryptionService } from "./credential-encryption.service.js";

export class AuthService {
  async loginWithGoogle(idToken: string): Promise<PublicUser> {
    const profile = await googleAuthService.verifyIdToken(idToken);
    const byGoogleId = await userRepository.findByGoogleId(profile.googleId);
    if (byGoogleId) {
      if (profile.avatarUrl) {
        await userRepository.updateAvatar(byGoogleId._id, profile.avatarUrl);
        byGoogleId.avatarUrl = profile.avatarUrl;
      }
      return userRepository.toPublicUser(byGoogleId);
    }

    const byEmail = profile.email ? await userRepository.findByEmail(profile.email) : null;
    if (byEmail) {
      await userRepository.linkGoogleId(byEmail._id, profile.googleId);
      if (profile.avatarUrl) await userRepository.updateAvatar(byEmail._id, profile.avatarUrl);
      const linked = await userRepository.findByGoogleId(profile.googleId);
      if (linked) return userRepository.toPublicUser(linked);
    }

    return userRepository.toPublicUser(await userRepository.create({
      googleId: profile.googleId,
      email: profile.email,
      name: profile.name,
      avatarUrl: profile.avatarUrl,
    }));
  }

  async loginWithErp(registrationNumber: string, password: string): Promise<PublicUser> {
    const registration = registrationNumber.trim();
    if (!registration || !password) throw new Error("ERP username and password are required");

    // Verify credentials against LRMS before creating or changing any app account.
    await lrmsBridgeService.createClient(registration, password);

    const existing = await userRepository.findByErpRegistrationNumber(registration);
    const erpCredential = {
      registrationNumber: registration,
      passwordCiphertext: credentialEncryptionService.encrypt(password),
      createdAt: new Date(),
    };

    if (existing) {
      await userRepository.bindErpCredentials(existing._id, erpCredential);
      const updated = await userRepository.findById(existing._id.toHexString());
      return userRepository.toPublicUser(updated!);
    }

    const created = await userRepository.create({
      name: registration,
      erpCredential,
    });
    return userRepository.toPublicUser(created);
  }
}

export const authService = new AuthService();
