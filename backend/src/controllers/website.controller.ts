import { Request, Response } from "express";

import { websiteService } from "../services/website.service.js";

/**
 * Serves content scraped from the public Loyola College website.
 */
export class WebsiteController {
  async listAnnouncements(_req: Request, res: Response) {
    try {
      const announcements = await websiteService.getAnnouncements();

      return res.json({ status: "success", data: announcements });
    } catch (error) {
      console.error("Website announcements error:", error);

      return res.status(502).json({
        status: "error",
        message: "Unable to fetch announcements from the college website",
      });
    }
  }
}

export const websiteController = new WebsiteController();