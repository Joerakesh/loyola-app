import { Request, Response, NextFunction } from "express";

import { appSessionService } from "../services/app-session.service.js";
import { userRepository } from "../repositories/user.repository.js";

export async function requireAuth(
  req: Request,
  res: Response,
  next: NextFunction,
) {
  try {
    const authorization = req.headers.authorization;

    if (!authorization) {
      return res.status(401).json({
        status: "error",
        message: "Authentication required",
      });
    }

    const [scheme, token] = authorization.split(" ");

    if (scheme !== "Bearer" || !token) {
      return res.status(401).json({
        status: "error",
        message: "Invalid authentication token",
      });
    }

    const payload = await appSessionService.verifySession(token);

    const user = await userRepository.findById(payload.sub);

    if (!user) {
      return res.status(401).json({
        status: "error",
        message: "Invalid or expired session",
      });
    }

    res.locals.user = userRepository.toPublicUser(user);
    res.locals.userDocument = user;

    next();
  } catch (error) {
    console.error("Authentication middleware error:", error);

    return res.status(401).json({
      status: "error",
      message: "Invalid or expired session",
    });
  }
}