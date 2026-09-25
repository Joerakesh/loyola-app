import { CALENDAR_CONFIG } from "../config/calendar.js";
import { CalendarRepository } from "../repositories/calendar.repository.js";
import { AcademicCalendarClient } from "../upstream/academic-calendar.client.js";
import {
  CalendarEvent,
  CalendarMonthDocument,
} from "../models/calendar.model.js";

function monthKey(year: number, month: number): string {
  return `${year}-${String(month).padStart(2, "0")}`;
}

function toIsoDate(date: Date): string {
  return [
    date.getUTCFullYear(),
    String(date.getUTCMonth() + 1).padStart(2, "0"),
    String(date.getUTCDate()).padStart(2, "0"),
  ].join("-");
}

/**
 * Keeps the Loyola College academic calendar in MongoDB:
 *  - a periodic sync of a rolling window around the current month
 *  - on-demand sync of any month a client asks for that isn't stored yet
 *  - background refresh of months whose data is older than the staleness TTL
 */
export class CalendarService {
  private readonly repository = new CalendarRepository();
  private readonly client = new AcademicCalendarClient();
  private readonly inflight = new Map<string, Promise<void>>();
  private timer: NodeJS.Timeout | null = null;

  /** Kicks off the periodic sync. Safe to call multiple times. */
  start(): void {
    if (this.timer) {
      return;
    }

    this.repository.ensureIndexes().catch((error) => {
      console.error("Calendar indexes error:", error);
    });

    // Initial pass so data is present soon after boot.
    this.syncWindow().catch((error) => {
      console.error("Calendar initial sync error:", error);
    });

    this.timer = setInterval(() => {
      this.syncWindow().catch((error) => {
        console.error("Calendar periodic sync error:", error);
      });
    }, CALENDAR_CONFIG.syncIntervalMinutes * 60_000);

    this.timer.unref();
  }

  /** Re-syncs the rolling window around the current month. */
  async syncWindow(force = false): Promise<void> {
    const now = new Date();

    const from = new Date(
      Date.UTC(
        now.getUTCFullYear(),
        now.getUTCMonth() - CALENDAR_CONFIG.monthsBefore,
        1,
      ),
    );
    const to = new Date(
      Date.UTC(
        now.getUTCFullYear(),
        now.getUTCMonth() + CALENDAR_CONFIG.monthsAfter + 1,
        0,
      ),
    );

    await this.ensureRange(from, to, force);
  }

  /**
   * Returns calendar days within [from, to] (inclusive), syncing any month in
   * the range that isn't stored and refreshing stale ones in the background.
   * Pass `force: true` to re-fetch the range immediately (used by `?refresh=1`).
   */
  async getEvents(
    from: Date,
    to: Date,
    options: { force?: boolean } = {},
  ): Promise<CalendarEvent[]> {
    await this.ensureRange(from, to, options.force ?? false);

    const months = this.monthsBetween(from, to);
    const docs = await this.repository.findByKeys(
      months.map((m) => monthKey(m.year, m.month)),
    );

    const fromKey = toIsoDate(from);
    const toKey = toIsoDate(to);

    const events: CalendarEvent[] = [];

    for (const doc of docs.sort((a, b) => a.key.localeCompare(b.key))) {
      for (const day of doc.days) {
        if (day.date >= fromKey && day.date <= toKey) {
          events.push({ ...day, monthKey: doc.key });
        }
      }
    }

    return events;
  }

  /** Fetches and upserts one month, deduplicating concurrent syncs. */
  async syncMonth(year: number, month: number): Promise<void> {
    const key = monthKey(year, month);
    const running = this.inflight.get(key);

    if (running) {
      return running;
    }

    const task = this.doSyncMonth(year, month)
      .catch((error) => {
        console.error(`Calendar sync failed for ${key}:`, error);
        throw error;
      })
      .finally(() => {
        this.inflight.delete(key);
      });

    this.inflight.set(key, task);

    return task;
  }

  private async doSyncMonth(year: number, month: number): Promise<void> {
    const fetched = await this.client.fetchMonth(year, month);

    const doc: Omit<CalendarMonthDocument, "_id" | "updatedAt"> = {
      year: fetched.year,
      month: fetched.month,
      key: monthKey(fetched.year, fetched.month),
      days: fetched.days,
      sourceUrl: fetched.sourceUrl,
      fetchedAt: new Date(),
    };

    await this.repository.upsertMonth(doc);

    console.log(
      `Calendar synced ${doc.key} — ${doc.days.length} day(s) with events/day orders`,
    );
  }

  private async ensureRange(
    from: Date,
    to: Date,
    force = false,
  ): Promise<void> {
    const months = this.monthsBetween(from, to);
    const keys = months.map((m) => monthKey(m.year, m.month));
    const stored = await this.repository.findByKeys(keys);
    const staleAfterMs = CALENDAR_CONFIG.staleAfterSeconds * 1000;
    const now = Date.now();

    const missing: Array<{ year: number; month: number }> = [];
    const stale: Array<{ year: number; month: number }> = [];

    for (const m of months) {
      const doc = stored.find((s) => s.key === monthKey(m.year, m.month));

      if (!doc) {
        missing.push(m);
      } else if (force || now - doc.fetchedAt.getTime() > staleAfterMs) {
        stale.push(m);
      }
    }

    // The response needs these months, so sync them inline.
    for (const m of missing) {
      await this.syncMonth(m.year, m.month).catch(() => {});
    }

    // Stale months normally refresh in the background (the response stays
    // fast); a forced refresh awaits so the caller gets fresh data.
    for (const m of stale) {
      const task = this.syncMonth(m.year, m.month);

      if (force) {
        await task.catch(() => {});
      } else {
        task.catch(() => {});
      }
    }
  }

  private monthsBetween(
    from: Date,
    to: Date,
  ): Array<{ year: number; month: number }> {
    const months: Array<{ year: number; month: number }> = [];

    let year = from.getUTCFullYear();
    let month = from.getUTCMonth() + 1;

    const endYear = to.getUTCFullYear();
    const endMonth = to.getUTCMonth() + 1;

    while (year < endYear || (year === endYear && month <= endMonth)) {
      months.push({ year, month });

      month += 1;
      if (month > 12) {
        month = 1;
        year += 1;
      }
    }

    return months;
  }
}

export const calendarService = new CalendarService();