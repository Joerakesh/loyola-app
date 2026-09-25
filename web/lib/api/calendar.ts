import { apiFetch } from "./client";
import type { CalendarResponse } from "../../types/api";

export interface CalendarQuery {
  /** "YYYY-MM" — one month. */
  month?: string;
  /** "YYYY-MM-DD" — the Mon–Sun week containing that date. */
  week?: string;
  /** "YYYY-MM-DD" — one day. */
  day?: string;
  /** "YYYY-MM-DD" inclusive range. */
  from?: string;
  to?: string;
}

/**
 * Public college academic calendar (GET /api/v1/calendar), auto-synced from
 * loyolacollege.edu into MongoDB. No auth token required.
 */
export async function getCalendar(
  query: CalendarQuery = {},
): Promise<CalendarResponse> {
  const params = new URLSearchParams();

  for (const [key, value] of Object.entries(query)) {
    if (value) {
      params.set(key, value);
    }
  }

  const qs = params.toString();

  return apiFetch<CalendarResponse>(`/calendar${qs ? `?${qs}` : ""}`);
}