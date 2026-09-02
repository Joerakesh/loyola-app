import { Request, Response } from "express";

import { authService } from "../services/auth.service.js";
import { lrmsSessionService } from "../services/lrms-session.service.js";

export class AuthController {
  async login(req: Request, res: Response) {
    try {
      const { registrationNumber, password } = req.body;

      if (!registrationNumber || !password) {
        return res.status(400).json({
          status: "error",
          message: "registrationNumber and password are required",
        });
      }

      const result = await authService.login(registrationNumber, password);

      return res.json({
        status: "success",
        authentication: {
          token: result.token,
          tokenType: "Bearer",
          expiresAt: result.expiresAt,
        },
      });
    } catch (error: any) {
      console.error("Authentication error:", error);

      return res.status(401).json({
        status: "error",
        message: "Login failed",
      });
    }
  }

  async logout(req: Request, res: Response) {
    try {
      const authorization = req.headers.authorization;

      if (!authorization?.startsWith("Bearer ")) {
        return res.status(401).json({
          status: "error",
          message: "Missing authentication token",
        });
      }

      const token = authorization.substring("Bearer ".length).trim();

      await lrmsSessionService.deleteSession(token);

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

  async refresh(req: Request, res: Response) {
    try {
      const { registrationNumber, password } = req.body;

      if (!registrationNumber || !password) {
        return res.status(400).json({
          status: "error",
          message: "registrationNumber and password are required",
        });
      }

      const result = await authService.refresh(registrationNumber, password);

      return res.json({
        status: "success",
        authentication: {
          token: result.token,
          tokenType: "Bearer",
          expiresAt: result.expiresAt,
        },
      });
    } catch (error) {
      console.error("Refresh authentication error:", error);

      return res.status(401).json({
        status: "error",
        message: "Unable to refresh session",
      });
    }
  }
}

export const authController = new AuthController();
