import type { Request, Response } from "express";
import { academicCalendarService } from "../services/academic-calendar.service.js";
import { academicCalendarRepository } from "../repositories/academic-calendar.repository.js";

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
      // App reads only the archived MongoDB snapshot; this endpoint never
      // contacts the college website.
      const data = await academicCalendarRepository.getMonth(year, month);
      if (!data) {
        return res.status(404).json({
          status: "error",
          message: "This calendar month has not been imported yet",
        });
      }
      res.setHeader("Cache-Control", "public, max-age=300, stale-while-revalidate=600");
      return res.json({ status: "success", data });
    } catch (error) {
      console.error("Academic calendar database read failed", {
        year,
        month,
        error: error instanceof Error ? error.message : String(error),
      });
      return res.status(503).json({
        status: "error",
        message: "Unable to read the academic calendar from storage",
      });
    }
  }

  async scrapeAndStore(req: Request, res: Response) {
    const now = new Date();
    const defaultStartYear = now.getUTCMonth() >= 5
      ? now.getUTCFullYear()
      : now.getUTCFullYear() - 1;
    const startYear = req.body?.startYear === undefined
      ? defaultStartYear
      : Number(req.body.startYear);

    if (!Number.isInteger(startYear) || startYear < 2000 || startYear > 2100) {
      return res.status(400).json({
        status: "error",
        message: "startYear must be an integer between 2000 and 2100",
      });
    }

    const results: Array<{
      year: number;
      month: number;
      status: "created" | "updated" | "unchanged" | "failed";
      version?: number;
      entries?: number;
      message?: string;
    }> = [];

    // Loyola's academic year runs June through May. Use small batches to
    // avoid flooding the public website while staying within serverless limits.
    const months = Array.from({ length: 12 }, (_, offset) => {
      const date = new Date(Date.UTC(startYear, 5 + offset, 1));
      return { year: date.getUTCFullYear(), month: date.getUTCMonth() + 1 };
    });

    for (let offset = 0; offset < months.length; offset += 4) {
      const batch = months.slice(offset, offset + 4);
      const batchResults = await Promise.all(batch.map(async ({ year, month }) => {
        try {
          const scraped = await academicCalendarService.scrapeMonth(year, month);
          const archived = await academicCalendarRepository.archiveMonth(scraped);
          return {
            year,
            month,
            status: archived.changed
              ? (archived.version === 1 ? "created" as const : "updated" as const)
              : "unchanged" as const,
            version: archived.version,
            entries: scraped.entries.length,
          };
        } catch (error) {
          // Keep the last known good MongoDB snapshot when the source is
          // temporarily unavailable or a page cannot be parsed.
          return {
            year,
            month,
            status: "failed" as const,
            message: error instanceof Error ? error.message : String(error),
          };
        }
      }));
      results.push(...batchResults);
    }

    const failed = results.filter((item) => item.status === "failed").length;
    const changed = results.filter((item) =>
      item.status === "created" || item.status === "updated",
    ).length;

    return res.status(failed === 12 ? 502 : 200).json({
      status: failed === 12 ? "error" : "success",
      academicYear: `${startYear}-${startYear + 1}`,
      summary: {
        months: results.length,
        changed,
        unchanged: results.filter((item) => item.status === "unchanged").length,
        failed,
      },
      data: results,
      completedAt: new Date().toISOString(),
    });
  }
}

export const academicCalendarController = new AcademicCalendarController();
