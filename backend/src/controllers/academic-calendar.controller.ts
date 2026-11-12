import type { Request, Response } from "express";
import { academicCalendarService } from "../services/academic-calendar.service.js";

export class AcademicCalendarController {
  async month(req: Request, res: Response) {
    const year = Number(req.query.year);
    const month = Number(req.query.month);

    if (!Number.isInteger(year) || year < 2000 || year > 2100) {
      return res.status(400).json({
        status: "error",
        message: "year must be an integer between 2000 and 2100",
      });
    }

    if (!Number.isInteger(month) || month < 1 || month > 12) {
      return res.status(400).json({
        status: "error",
        message: "month must be an integer between 1 and 12",
      });
    }

    try {
      const data = await academicCalendarService.getMonth(year, month, req.query.refresh === "1");
      res.setHeader("Cache-Control", "public, max-age=300, stale-while-revalidate=600");
      return res.json({ status: "success", data });
    } catch (error) {
      console.error("Academic calendar fetch failed", {
        year,
        month,
        refresh: req.query.refresh === "1",
        error: error instanceof Error ? error.message : String(error),
        stack: error instanceof Error ? error.stack : undefined,
      });
      return res.status(502).json({
        status: "error",
        message: "Unable to fetch the requested academic calendar month from Loyola College",
      });
    }
  }
}

export const academicCalendarController = new AcademicCalendarController();
