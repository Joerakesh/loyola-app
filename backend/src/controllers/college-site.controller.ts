import { Request, Response } from "express";
import { collegeSiteService } from "../services/college-site.service.js";

export class CollegeSiteController {
  async updates(req: Request, res: Response) {
    try {
      const data = await collegeSiteService.getUpdates({
        refresh: req.query.refresh === "1",
      });

      res.setHeader(
        "Cache-Control",
        "public, max-age=300, stale-while-revalidate=600",
      );

      return res.json({
        status: "success",
        data,
      });
    } catch (error) {
      console.error(
        "College website scrape failed:",
        error instanceof Error ? error.message : error,
      );

      return res.status(502).json({
        status: "error",
        message: "Unable to fetch updates from the Loyola College website",
      });
    }
  }
}

export const collegeSiteController = new CollegeSiteController();
