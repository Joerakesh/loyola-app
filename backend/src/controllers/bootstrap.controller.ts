import { Request, Response } from "express";

import { BootstrapService } from "../services/bootstrap.service.js";
import { lrmsBridgeService } from "../services/lrms-bridge.service.js";

export class BootstrapController {
  async index(req: Request, res: Response) {
    try {
      const client = res.locals.lrmsClient;
      const user = res.locals.userDocument;

      try {
        const payload = await new BootstrapService(client).getPayload();

        return res.json({
          status: "success",
          data: payload,
        });
      } catch (firstError) {
        // A cached LRMS session may have expired server-side. Drop the cached
        // session, log in fresh, and retry once before giving up.
        console.error(
          "Bootstrap load failed, retrying with a fresh LRMS session:",
          firstError,
        );

        await lrmsBridgeService.invalidateSessionForUser(user);

        const freshClient = await lrmsBridgeService.createClientForUser(user);

        const payload = await new BootstrapService(freshClient).getPayload();

        return res.json({
          status: "success",
          data: payload,
        });
      }
    } catch (error) {
      console.error("Bootstrap error:", error);

      return res.status(502).json({
        status: "error",
        message: "Unable to load dashboard data",
      });
    }
  }
}

export const bootstrapController = new BootstrapController();