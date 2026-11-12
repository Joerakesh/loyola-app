import { Request, Response, NextFunction } from "express";
import { lrmsBridgeService } from "../services/lrms-bridge.service.js";

/**
 * Attaches a lazy ERP client. No network call happens here: the session is
 * created (or reused from cache) on the first request the controller makes.
 */
export function requireErpClient(
  req: Request,
  res: Response,
  next: NextFunction,
) {
  const user = res.locals.userDocument;

  if (!user?.erpCredential) {
    return res.status(403).json({
      status: "error",
      message: "ERP credentials not linked",
    });
  }

  res.locals.lrmsClient = lrmsBridgeService.getClientForUser(user);

  next();
}
