import { Request, Response } from "express";

import { authService } from "../services/auth.service.js";
import { appSessionService } from "../services/app-session.service.js";
import { lrmsBridgeService } from "../services/lrms-bridge.service.js";
import { credentialEncryptionService } from "../services/credential-encryption.service.js";
import { userRepository } from "../repositories/user.repository.js";
import { PublicUser } from "../models/user.model.js";

export class AuthController {
  async googleLogin(req: Request, res: Response) {
    try {
      const { idToken } = req.body;

      if (!idToken || typeof idToken !== "string") {
        return res.status(400).json({
          status: "error",
          message: "idToken is required",
        });
      }

      const user = await authService.loginWithGoogle(idToken);
      const session = await appSessionService.createSession(user);

      return res.json({
        status: "success",
        user,
        authentication: {
          token: session.token,
          tokenType: "Bearer",
          expiresAt: session.expiresAt,
        },
      });
    } catch (error: any) {
      console.error("Google authentication error:", error);

      return res.status(401).json({
        status: "error",
        message: "Google login failed",
      });
    }
  }

  async me(req: Request, res: Response) {
    try {
      const user = res.locals.user as PublicUser;

      return res.json({ status: "success", user });
    } catch (error) {
      console.error("Profile error:", error);

      return res.status(500).json({
        status: "error",
        message: "Unable to load profile",
      });
    }
  }

  async refresh(req: Request, res: Response) {
    try {
      const user = res.locals.user as PublicUser;

      const session = await appSessionService.createSession(user);

      return res.json({
        status: "success",
        authentication: {
          token: session.token,
          tokenType: "Bearer",
          expiresAt: session.expiresAt,
        },
      });
    } catch (error) {
      console.error("Refresh error:", error);

      return res.status(401).json({
        status: "error",
        message: "Unable to refresh session",
      });
    }
  }

  async logout(req: Request, res: Response) {
    try {
      return res.json({
        status: "success",
        message: "Logged out successfully",
      });
    } catch (error) {
      console.error("Logout error:", error);

      return res.status(500).json({
        status: "error",
        message: "Unable to logout",
      });
    }
  }

  async bindErp(req: Request, res: Response) {
    try {
      const user = res.locals.userDocument;

      const { registrationNumber, password, email } = req.body;

      if (!registrationNumber || !password) {
        return res.status(400).json({
          status: "error",
          message: "registrationNumber and password are required",
        });
      }

      const normalizedEmail = email ? email.trim().toLowerCase() : "";

      if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalizedEmail)) {
        return res.status(400).json({
          status: "error",
          message: "Invalid email address",
        });
      }

      if (
        normalizedEmail &&
        (user.linkedEmails ?? []).includes(normalizedEmail)
      ) {
        return res.status(400).json({
          status: "error",
          message: "Email is already linked to this account",
        });
      }

      if (normalizedEmail && normalizedEmail !== user.email) {
        const existing = await userRepository.findByEmail(normalizedEmail);

        if (existing && existing._id.toHexString() !== user._id.toHexString()) {
          return res.status(409).json({
            status: "error",
            message: "Email is already linked to another account",
          });
        }
      }

      await lrmsBridgeService.createClient(
        registrationNumber,
        password,
      );

      const passwordCiphertext = credentialEncryptionService.encrypt(password);

      await userRepository.bindErpCredentials(user._id, {
        registrationNumber,
        passwordCiphertext,
        createdAt: new Date(),
      });

      if (normalizedEmail && normalizedEmail !== user.email) {
        await userRepository.bindEmail(user._id, normalizedEmail);
      }

      const updated = await userRepository.findById(user._id.toHexString());

      return res.json({
        status: "success",
        user: userRepository.toPublicUser(updated!),
      });
    } catch (error) {
      console.error("Bind ERP error:", error);

      return res.status(400).json({
        status: "error",
        message: "Unable to link ERP credentials",
      });
    }
  }

  async bindEmail(req: Request, res: Response) {
    try {
      const user = res.locals.userDocument;

      const { email } = req.body;

      if (!email || typeof email !== "string") {
        return res.status(400).json({
          status: "error",
          message: "email is required",
        });
      }

      const normalized = email.trim().toLowerCase();

      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalized)) {
        return res.status(400).json({
          status: "error",
          message: "Invalid email address",
        });
      }

      if (user.email === normalized || (user.linkedEmails ?? []).includes(normalized)) {
        return res.status(400).json({
          status: "error",
          message: "Email is already linked to this account",
        });
      }

      const existing = await userRepository.findByEmail(normalized);

      if (existing && existing._id.toHexString() !== user._id.toHexString()) {
        return res.status(409).json({
          status: "error",
          message: "Email is already linked to another account",
        });
      }

      await userRepository.bindEmail(user._id, normalized);

      const updated = await userRepository.findById(user._id.toHexString());

      return res.json({
        status: "success",
        user: userRepository.toPublicUser(updated!),
      });
    } catch (error) {
      console.error("Bind email error:", error);

      return res.status(500).json({
        status: "error",
        message: "Unable to link email",
      });
    }
  }

  async unbindErp(req: Request, res: Response) {
    try {
      const user = res.locals.userDocument;

      await userRepository.clearErpCredentials(user._id);

      const updated = await userRepository.findById(user._id.toHexString());

      return res.json({
        status: "success",
        user: userRepository.toPublicUser(updated!),
      });
    } catch (error) {
      console.error("Unbind ERP error:", error);

      return res.status(500).json({
        status: "error",
        message: "Unable to unlink ERP credentials",
      });
    }
  }
}

export const authController = new AuthController();