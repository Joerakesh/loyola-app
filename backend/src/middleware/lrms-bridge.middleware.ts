import { Request, Response, NextFunction } from "express";
import { lrmsBridgeService } from "../services/lrms-bridge.service.js";

export async function requireErpClient(
  req: Request,
  res: Response,
  next: NextFunction,
) {
  try {
    const user = res.locals.userDocument;

    if (!user?.erpCredential) {
      return res.status(403).json({
        status: "error",
        message: "ERP credentials not linked",
      });
    }

    const client = await lrmsBridgeService.createClientForUser(user);

    res.locals.lrmsClient = client;

    next();
  } catch (error) {
    console.error("LRMS bridge error:", error);

    return res.status(502).json({
      status: "error",
      message: "Unable to connect to LRMS",
    });
  }
}