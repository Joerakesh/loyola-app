import { ObjectId } from "mongodb";

export interface CalendarDay {
  /** ISO date, e.g. "2026-10-01". */
  date: string;
  /** Short weekday, e.g. "THU". */
  day: string;
  /** "Day-1" … "Day-6", or null when the day has no day order. */
  dayOrder: string | null;
  /** Event title(s), or null when the day only carries a day order. */
  event: string | null;
}

export interface CalendarMonthDocument {
  _id: ObjectId;
  year: number;
  /** 1-12 */
  month: number;
  /** "YYYY-MM", unique per month. */
  key: string;
  days: CalendarDay[];
  /** URL the month was scraped from. */
  sourceUrl: string;
  fetchedAt: Date;
  updatedAt: Date;
}

/** Event exposed through the API: a stored day enriched with its month key. */
export type CalendarEvent = CalendarDay & { monthKey: string };