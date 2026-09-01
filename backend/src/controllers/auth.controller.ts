import { Request, Response } from "express";

import { authService } from "../services/auth.service.js";

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
}

export const authController = new AuthController();
