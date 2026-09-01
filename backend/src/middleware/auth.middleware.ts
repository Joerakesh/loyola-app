import { Request, Response, NextFunction } from "express";

import { lrmsSessionService } from "../services/lrms-session.service.js";

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

    const client = await lrmsSessionService.getSession(token);

    res.locals.lrmsClient = client;

    next();
  } catch (error) {
    console.error("Authentication middleware error:", error);

    return res.status(401).json({
      status: "error",
      message: "Invalid or expired session",
    });
  }
}
