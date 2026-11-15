import type { Request, Response } from "express";
import { collegeSiteService } from "../services/college-site.service.js";
import { collegeUpdatesRepository } from "../repositories/college-updates.repository.js";
import { academicCalendarRepository } from "../repositories/academic-calendar.repository.js";

export class CollegeSiteController {
  async updates(_req: Request, res: Response) {
    try {
      // The app reads the last successful MongoDB archive. It never scrapes
      // Loyola's website as part of a normal read request.
      const snapshot = await collegeUpdatesRepository.getLatest();
      if (!snapshot) {
        return res.status(404).json({
          status: "error",
          message: "College announcements and events have not been imported yet",
        });
      }

      const now = new Date();
      const year = now.getUTCFullYear();
      const monthNumber = now.getUTCMonth() + 1;
      const archivedCalendar = await academicCalendarRepository.getMonth(year, monthNumber);

      res.setHeader("Cache-Control", "public, max-age=300, stale-while-revalidate=600");
      return res.json({
        status: "success",
        data: {
          ...snapshot,
          calendar: {
            month: archivedCalendar?.month ?? "",
            entries: archivedCalendar?.entries.map((entry) => ({
              dateLabel: entry.dateLabel,
              event: entry.event,
              ...(entry.dayOrder ? { dayOrder: entry.dayOrder } : {}),
            })) ?? [],
            sourceUrl: archivedCalendar?.sourceUrl ?? snapshot.sources.calendar,
          },
        },
      });
    } catch (error) {
      console.error("College updates database read failed:", error);
      return res.status(503).json({
        status: "error",
        message: "Unable to read college updates from storage",
      });
    }
  }

  async scrapeAndStore(_req: Request, res: Response) {
    try {
      const acquired = await collegeUpdatesRepository.acquireScrapeSlot();
      if (!acquired) {
        return res.status(429).json({
          status: "error",
          message: "A college updates refresh was recently started. Try again in a few minutes.",
        });
      }
      const snapshot = await collegeSiteService.scrapeForArchive();
      const result = await collegeUpdatesRepository.archive(snapshot);
      return res.json({
        status: "success",
        ...result,
        completedAt: new Date().toISOString(),
      });
    } catch (error) {
      console.error(
        "College announcements/events scrape failed:",
        error instanceof Error ? error.message : error,
      );
      return res.status(502).json({
        status: "error",
        message: "Unable to scrape Loyola College announcements and events; the previous MongoDB archive was preserved",
      });
    }
  }
}

export const collegeSiteController = new CollegeSiteController();
