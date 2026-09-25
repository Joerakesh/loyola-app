import { Request, Response } from "express";

import { CALENDAR_CONFIG } from "../config/calendar.js";
import { calendarService } from "../services/calendar.service.js";

const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;
const MONTH_RE = /^\d{4}-(0[1-9]|1[0-2])$/;

/** Parse "YYYY-MM-DD" strictly (rejects 2026-02-31 instead of normalizing). */
function parseStrictDate(value: string): Date | null {
  if (!DATE_RE.test(value)) {
    return null;
  }

  const [year, month, day] = value.split("-").map(Number);
  const date = new Date(Date.UTC(year, month - 1, day));

  if (
    date.getUTCFullYear() !== year ||
    date.getUTCMonth() !== month - 1 ||
    date.getUTCDate() !== day
  ) {
    return null;
  }

  return date;
}

/**
 * Serves the college academic calendar stored in MongoDB.
 *
 * Query filters (all optional):
 *   - (none)      → the synced window around the current month
 *   - month=2026-10      → one month
 *   - week=2026-10-05    → the Mon–Sun week containing that date
 *   - day=2026-10-07     → one day (alias: date=)
 *   - from=YYYY-MM-DD&to=YYYY-MM-DD → inclusive range (week/month/all)
 *   - refresh=1          → re-fetch the requested range from the college site
 *                          now instead of serving the cached/stale copy
 */
export class CalendarController {
  async list(req: Request, res: Response) {
    try {
      const range = this.parseRange(req.query);

      if (!range.ok) {
        return res.status(400).json({
          status: "error",
          message: range.error,
        });
      }

      const refreshRaw = req.query.refresh;
      const forceRefresh =
        refreshRaw === "1" || refreshRaw === "true" || refreshRaw === "yes";

      const events = await calendarService.getEvents(range.from, range.to, {
        force: forceRefresh,
      });

      return res.json({
        status: "success",
        count: events.length,
        from: this.toIso(range.from),
        to: this.toIso(range.to),
        data: events,
      });
    } catch (error) {
      console.error("Calendar list error:", error);

      return res.status(502).json({
        status: "error",
        message: "Unable to fetch academic calendar",
      });
    }
  }

  private parseRange(query: Request["query"]):
    | { ok: false; error: string }
    | { ok: true; from: Date; to: Date } {
    const value = (key: string): string | undefined => {
      const v = query[key];
      return typeof v === "string" ? v : undefined;
    };

    const month = value("month");
    const week = value("week");
    const day = value("day") ?? value("date");
    const fromRaw = value("from");
    const toRaw = value("to");

    if (month) {
      if (!MONTH_RE.test(month)) {
        return { ok: false, error: "month must be YYYY-MM (e.g. month=2026-10)" };
      }
      const [year, monthNumber] = month.split("-").map(Number);
      const from = new Date(Date.UTC(year, monthNumber - 1, 1));
      const to = new Date(Date.UTC(year, monthNumber, 0));

      return { ok: true, from, to };
    }

    if (week) {
      const anchor = parseStrictDate(week);
      if (!anchor) {
        return { ok: false, error: "week must be a valid date YYYY-MM-DD" };
      }
      // Monday-based week.
      const mondayOffset = (anchor.getUTCDay() + 6) % 7;
      const from = new Date(
        Date.UTC(
          anchor.getUTCFullYear(),
          anchor.getUTCMonth(),
          anchor.getUTCDate() - mondayOffset,
        ),
      );
      const to = new Date(
        Date.UTC(
          from.getUTCFullYear(),
          from.getUTCMonth(),
          from.getUTCDate() + 6,
        ),
      );

      return { ok: true, from, to };
    }

    if (day) {
      const date = parseStrictDate(day);
      if (!date) {
        return { ok: false, error: "day must be a valid date YYYY-MM-DD" };
      }

      return { ok: true, from: date, to: date };
    }

    if (fromRaw !== undefined || toRaw !== undefined) {
      const from = fromRaw ? parseStrictDate(fromRaw) : null;
      const to = toRaw ? parseStrictDate(toRaw) : null;

      if ((fromRaw && !from) || (toRaw && !to)) {
        return { ok: false, error: "from/to must be valid dates YYYY-MM-DD" };
      }

      if (from && to && from > to) {
        return { ok: false, error: "from must be on or before to" };
      }

      const now = new Date();

      return {
        ok: true,
        from: from ?? new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - CALENDAR_CONFIG.monthsBefore, 1)),
        to: to ?? new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + CALENDAR_CONFIG.monthsAfter + 1, 0)),
      };
    }

    // No filters → the full synced window (i.e. "all").
    const now = new Date();

    return {
      ok: true,
      from: new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - CALENDAR_CONFIG.monthsBefore, 1)),
      to: new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + CALENDAR_CONFIG.monthsAfter + 1, 0)),
    };
  }

  private toIso(date: Date): string {
    const year = date.getUTCFullYear();

    return [
      year,
      String(date.getUTCMonth() + 1).padStart(2, "0"),
      String(date.getUTCDate()).padStart(2, "0"),
    ].join("-");
  }
}

export const calendarController = new CalendarController();