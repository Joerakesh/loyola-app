import { userRepository } from "../repositories/user.repository.js";
import { PublicUser } from "../models/user.model.js";
import { googleAuthService } from "./google-auth.service.js";

export class AuthService {
  async loginWithGoogle(idToken: string): Promise<PublicUser> {
    const profile = await googleAuthService.verifyIdToken(idToken);

    const byGoogleId = await userRepository.findByGoogleId(profile.googleId);

    if (byGoogleId) {
      return userRepository.toPublicUser(byGoogleId);
    }

    const byEmail = profile.email
      ? await userRepository.findByEmail(profile.email)
      : null;

    if (byEmail) {
      await userRepository.linkGoogleId(byEmail._id, profile.googleId);

      const linked = await userRepository.findByGoogleId(profile.googleId);

      if (linked) {
        return userRepository.toPublicUser(linked);
      }
    }

    const user = await userRepository.create({
      googleId: profile.googleId,
      email: profile.email,
      name: profile.name,
      avatarUrl: profile.avatarUrl,
    });

    return userRepository.toPublicUser(user);
  }
}

export const authService = new AuthService();