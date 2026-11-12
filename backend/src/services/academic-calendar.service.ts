import axios from "axios";
import * as cheerio from "cheerio";

const ORIGIN = "https://www.loyolacollege.edu";
const TTL = 5 * 60_000;
const MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
const MONTH_INDEX: Record<string, number> = { jan: 0, feb: 1, mar: 2, apr: 3, may: 4, jun: 5, jul: 6, aug: 7, sep: 8, oct: 9, nov: 10, dec: 11 };

export interface CalendarEntry {
  dateLabel: string;
  date?: string;
  day?: string;
  event: string;
  dayOrder?: string;
}

export interface AcademicCalendarMonth {
  year: number;
  monthNumber: number;
  month: string;
  entries: CalendarEntry[];
  sourceUrl: string;
  fetchedAt: string;
}

const http = axios.create({
  timeout: 15_000,
  maxRedirects: 5,
  headers: {
    "User-Agent": "LoyolaStudentApp/1.0 (+https://github.com/Joerakesh/loyola-app)",
    Accept: "application/json, text/html, */*",
  },
});

const cache = new Map<string, { expiresAt: number; value: AcademicCalendarMonth }>();
const inFlight = new Map<string, Promise<AcademicCalendarMonth>>();

function clean(value: string): string {
  return value.replace(/\s+/g, " ").trim();
}

function getMarkup(payload: unknown): string {
  if (typeof payload === "string") return payload;
  if (Array.isArray(payload)) return payload.map(getMarkup).join(" ");
  if (payload && typeof payload === "object") {
    const record = payload as Record<string, unknown>;
    for (const key of ["html", "data", "content", "result", "calendar", "response"]) {
      if (record[key] !== undefined) {
        const value = getMarkup(record[key]);
        if (value) return value;
      }
    }
    return Object.values(record).map(getMarkup).join(" ");
  }
  return "";
}

function normalizeDate(label: string, year: number, monthNumber: number): { date?: string; day?: string } {
  const match = label.match(/(\d{1,2})\s+([A-Za-z]{3,})/);
  if (!match) return {};
  const dayNumber = Number(match[1]);
  const monthIndex = MONTH_INDEX[match[2].slice(0, 3).toLowerCase()];
  if (monthIndex === undefined || monthIndex + 1 !== monthNumber || dayNumber < 1 || dayNumber > 31) return {};
  const date = new Date(Date.UTC(year, monthIndex, dayNumber));
  if (date.getUTCMonth() !== monthIndex || date.getUTCDate() !== dayNumber) return {};
  return {
    date: year + "-" + String(monthNumber).padStart(2, "0") + "-" + String(dayNumber).padStart(2, "0"),
    day: new Intl.DateTimeFormat("en", { weekday: "long", timeZone: "UTC" }).format(date),
  };
}

/**
 * Only retain rows whose date can be normalized into the requested month.
 * The upstream page can return an adjacent month's calendar, so accepting
 * unvalidated rows would silently label the wrong month as the requested one.
 */
function parseEntries(markup: string, year: number, monthNumber: number): CalendarEntry[] {
  const $ = cheerio.load(markup);
  const entries: CalendarEntry[] = [];
  const seen = new Set<string>();

  $("tr").each((_, row) => {
    const cells = $(row).find("th, td").toArray().map((cell) => clean($(cell).text()));
    if (cells.length < 2 || /^date$/i.test(cells[0] ?? "")) return;

    const dateLabel = cells[0] ?? "";
    const event = cells[1] ?? "";
    if (!/\d/.test(dateLabel)) return;

    const normalized = normalizeDate(dateLabel, year, monthNumber);
    if (!normalized.date) return;

    const dayOrderCell = cells[2] ?? "";
    const key = [normalized.date, event, dayOrderCell].join("|");
    if (seen.has(key)) return;
    seen.add(key);

    entries.push({
      dateLabel,
      event,
      ...normalized,
      ...(dayOrderCell && /day\s*[- ]?\d+/i.test(dayOrderCell)
        ? { dayOrder: dayOrderCell.match(/day\s*[- ]?\d+/i)?.[0] }
        : {}),
    });
  });

  return entries;
}

function parsePayload(data: unknown): string {
  let payload = data;
  if (typeof payload === "string") {
    const trimmed = payload.trim();
    if (trimmed.startsWith("{") || trimmed.startsWith("[")) {
      try {
        payload = JSON.parse(trimmed) as unknown;
      } catch {
        // The endpoint may return an HTML fragment rather than JSON.
      }
    }
  }
  return getMarkup(payload);
}

function getErrorMessage(error: unknown): string {
  if (axios.isAxiosError(error)) {
    const status = error.response?.status;
    return status
      ? `upstream HTTP ${status}: ${error.message}`
      : error.message;
  }
  return error instanceof Error ? error.message : String(error);
}

export class AcademicCalendarService {
  async getMonth(year: number, monthNumber: number, refresh = false): Promise<AcademicCalendarMonth> {
    const key = year + "-" + String(monthNumber).padStart(2, "0");
    const cached = cache.get(key);
    if (!refresh && cached && cached.expiresAt > Date.now()) return cached.value;

    const pending = inFlight.get(key);
    if (!refresh && pending) return pending;

    const request = this.fetchMonth(year, monthNumber)
      .then((value) => {
        cache.set(key, { value, expiresAt: Date.now() + TTL });
        return value;
      })
      .finally(() => inFlight.delete(key));

    inFlight.set(key, request);
    return request;
  }

  private async fetchMonth(year: number, monthNumber: number): Promise<AcademicCalendarMonth> {
    // Loyola's endpoint appears to use a zero-based month in some responses.
    // Try that first, then the one-based form for compatibility. Every response
    // is checked against the requested month before it can be returned or cached.
    const upstreamMonths = [...new Set([monthNumber - 1, monthNumber])];
    const failures: string[] = [];

    for (const upstreamMonth of upstreamMonths) {
      const sourceUrl = `${ORIGIN}/acnew.php?action=list_next&year=${year}&month=${upstreamMonth}`;

      try {
        const response = await http.get(sourceUrl, {
          responseType: "text",
          transformResponse: [(data) => data],
        });

        const entries = parseEntries(parsePayload(response.data), year, monthNumber);
        if (entries.length === 0) {
          failures.push(`month=${upstreamMonth}: response contained no rows for ${MONTHS[monthNumber - 1]} ${year}`);
          continue;
        }

        return {
          year,
          monthNumber,
          month: MONTHS[monthNumber - 1],
          entries,
          sourceUrl,
          fetchedAt: new Date().toISOString(),
        };
      } catch (error) {
        failures.push(`month=${upstreamMonth}: ${getErrorMessage(error)}`);
      }
    }

    throw new Error(
      `Could not retrieve ${MONTHS[monthNumber - 1]} ${year} from Loyola College calendar. ${failures.join("; ")}`,
    );
  }
}

export const academicCalendarService = new AcademicCalendarService();
