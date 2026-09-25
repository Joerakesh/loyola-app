import axios from "axios";
import * as cheerio from "cheerio";

import { CALENDAR_CONFIG } from "../config/calendar.js";
import { CalendarDay } from "../models/calendar.model.js";

const MONTH_NAMES = [
  "January",
  "February",
  "March",
  "April",
  "May",
  "June",
  "July",
  "August",
  "September",
  "October",
  "November",
  "December",
];

const MONTH_ABBR: Record<string, number> = {
  Jan: 1,
  Feb: 2,
  Mar: 3,
  Apr: 4,
  May: 5,
  Jun: 6,
  Jul: 7,
  Aug: 8,
  Sep: 9,
  Oct: 10,
  Nov: 11,
  Dec: 12,
};

const WEEKDAYS = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];

export interface FetchedMonth {
  /** Displayed month (parsed from the page, authoritative). */
  year: number;
  month: number;
  days: CalendarDay[];
  sourceUrl: string;
}

function isoDate(year: number, month: number, day: number): string {
  return `${year}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
}

function weekdayOf(dateKey: string): string {
  const [year, month, day] = dateKey.split("-").map(Number);

  return WEEKDAYS[new Date(Date.UTC(year, month - 1, day)).getUTCDay()];
}

function clean(text: string): string {
  return text.replace(/\s+/g, " ").trim();
}

function normalizeDayOrder(text: string): string | null {
  const value = clean(text);

  return !value || value === "—" || value === "-" ? null : value;
}

function normalizeEvent(text: string): string | null {
  const value = clean(text);

  return !value || value === "—" ? null : value;
}

export class AcademicCalendarClient {
  private readonly client;

  constructor() {
    this.client = axios.create({
      baseURL: CALENDAR_CONFIG.baseUrl,
      timeout: CALENDAR_CONFIG.fetchTimeoutMs,
      headers: {
        "User-Agent": "Mozilla/5.0 (compatible; CollegeMobileApp/1.0)",
        Accept: "text/html",
      },
    });
  }

  /**
   * Fetches one month. The college site's `action=list_next&month=M` page
   * displays month M+1, so we request with M-1 and attribute the parsed rows
   * to the month shown in the page header.
   *
   * The page renders the month twice — a list-view table and a calendar grid —
   * and the two are not always consistent (e.g. 2026-09-25 appears only in the
   * calendar grid). Both views are parsed and merged before storing.
   */
  async fetchMonth(year: number, month: number): Promise<FetchedMonth> {
    const [paramYear, paramMonth] =
      month === 1 ? [year - 1, 12] : [year, month - 1];

    const query = [
      "action=list_next",
      `year=${paramYear}`,
      `month=${String(paramMonth).padStart(2, "0")}`,
    ].join("&");

    const url = `${CALENDAR_CONFIG.baseUrl}?${query}`;
    const response = await this.client.get<string>(url);

    const $ = cheerio.load(response.data);

    const headerMatch = $(".list-view-header h4")
      .first()
      .text()
      .trim()
      .match(/^([A-Za-z]+)\s+(\d{4})$/);

    if (!headerMatch) {
      throw new Error(
        `acnew.php did not return an expected month header (requested ${year}-${month})`,
      );
    }

    const displayedMonth = MONTH_NAMES.indexOf(headerMatch[1]) + 1;
    const displayedYear = Number(headerMatch[2]);

    if (displayedYear !== year || displayedMonth !== month) {
      throw new Error(
        `acnew.php returned ${displayedMonth}/${displayedYear} while ${month}/${year} was requested — calendar layout may have changed`,
      );
    }

    const daysByDate = new Map<string, CalendarDay>();

    // 1) List-view table (authoritative for rows it contains).
    $(".events-table tbody tr.event-row").each((_index, element) => {
      const $row = $(element);

      const dateText = $row.find(".date-number-large").first().text().trim();
      const [dayText, monthAbbr] = dateText.split(/\s+/);

      const dayNumber = Number(dayText);
      const monthNumber = MONTH_ABBR[monthAbbr];

      if (!dayNumber || !monthNumber) {
        return;
      }

      const date = isoDate(displayedYear, monthNumber, dayNumber);

      daysByDate.set(date, {
        date,
        day: $row.find(".day-abbr").first().text().trim(),
        dayOrder: normalizeDayOrder(
          $row.find("td").last().first().text(),
        ),
        event: normalizeEvent($row.find(".events-cell").first().text()),
      });
    });

    // 2) Calendar-grid view — catches days the list table omits (e.g. today's
    //    "Corpus Christi Celebration", present only here on the live site).
    $(".calendar-view-container .calendar-cell").each((_index, element) => {
      const $cell = $(element);

      const dayText = $cell.find(".date-number").first().text().trim();
      const dayNumber = Number(dayText);

      if (!dayNumber) {
        return;
      }

      const eventText = $cell.find(".event-text").first().text();
      const orderText = $cell.find(".day-order-badge").first().text();

      if (!eventText.trim() && !orderText.trim()) {
        return; // plain day cell — nothing to record
      }

      const date = isoDate(displayedYear, displayedMonth, dayNumber);
      const existing = daysByDate.get(date);

      if (existing) {
        if (!existing.dayOrder && orderText.trim()) {
          existing.dayOrder = normalizeDayOrder(orderText);
        }
        if (!existing.event) {
          existing.event = normalizeEvent(eventText);
        }
      } else {
        daysByDate.set(date, {
          date,
          day: weekdayOf(date),
          dayOrder: normalizeDayOrder(orderText),
          event: normalizeEvent(eventText),
        });
      }
    });

    const days = [...daysByDate.values()].sort((a, b) =>
      a.date.localeCompare(b.date),
    );

    return {
      year: displayedYear,
      month: displayedMonth,
      days,
      sourceUrl: url,
    };
  }
}