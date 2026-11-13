import type { Request, Response } from "express";
import { googleAuthService } from "../services/google-auth.service.js";
import { userRepository } from "../repositories/user.repository.js";

export async function bindGoogleIdentity(req: Request, res: Response) {
  try {
    const user = res.locals.userDocument;
    const { idToken } = req.body ?? {};
    if (!user?.erpCredential?.registrationNumber) {
      return res.status(409).json({ status: "error", message: "Sign in with your ERP account before linking Google." });
    }
    if (typeof idToken !== "string" || !idToken.trim()) {
      return res.status(400).json({ status: "error", message: "A Firebase Google ID token is required." });
    }

    const profile = await googleAuthService.verifyIdToken(idToken);
    const currentId = user._id.toHexString();
    const existingGoogle = await userRepository.findByGoogleId(profile.googleId);
    if (existingGoogle && existingGoogle._id.toHexString() !== currentId) {
      return res.status(409).json({ status: "error", message: "This Google account is already linked to another student account." });
    }

    const email = profile.email?.trim().toLowerCase();
    if (email) {
      const existingEmail = await userRepository.findByEmail(email);
      if (existingEmail && existingEmail._id.toHexString() !== currentId) {
        return res.status(409).json({ status: "error", message: "This Google email is already associated with another student account. Accounts are not merged automatically." });
      }
    }

    await userRepository.linkGoogleIdentity(user._id, {
      googleId: profile.googleId,
      ...(email ? { email } : {}),
      ...(profile.name ? { name: profile.name } : {}),
      ...(profile.avatarUrl ? { avatarUrl: profile.avatarUrl } : {}),
    });
    const updated = await userRepository.findById(currentId);
    if (!updated) return res.status(500).json({ status: "error", message: "Unable to reload the linked student account." });
    return res.json({ status: "success", message: "Google identity linked to the existing ERP account.", user: userRepository.toPublicUser(updated) });
  } catch (error) {
    if ((error as { code?: number })?.code === 11000) {
      return res.status(409).json({ status: "error", message: "This Google identity or email is already linked to another account." });
    }
    console.error("Google identity linking error:", error instanceof Error ? error.message : "Unknown error");
    return res.status(401).json({ status: "error", message: "Unable to verify or link this Google identity." });
  }
}
