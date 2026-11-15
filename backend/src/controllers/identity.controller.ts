import type { Request, Response } from "express";
import { userRepository } from "../repositories/user.repository.js";

export async function bindGoogleIdentity(_req: Request, res: Response) {
  return res.status(410).json({ status: "error", message: "Google identities are separate accounts. Sign out and sign in with the other Google account instead." });
}

export async function unbindGoogleIdentity(_req: Request, res: Response) {
  try {
    const user = res.locals.userDocument;
    if (!user?.erpCredential?.registrationNumber) {
      return res.status(409).json({ status: "error", message: "Link and verify ERP credentials before revoking Google sign-in. This prevents losing access to your account." });
    }
    await userRepository.clearGoogleIdentity(user._id);
    return res.json({ status: "success", message: "Google sign-in was revoked for this account. Sign in with ERP to access it again." });
  } catch (error) {
    console.error("Google identity revoke error:", error instanceof Error ? error.message : "Unknown error");
    return res.status(500).json({ status: "error", message: "Unable to revoke Google sign-in." });
  }
}
