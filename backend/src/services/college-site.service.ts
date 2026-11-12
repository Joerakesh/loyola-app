import axios from "axios";
import * as cheerio from "cheerio";

const SITE_ORIGIN = "https://www.loyolacollege.edu";
const HOME_URL = `${SITE_ORIGIN}/`;
const CALENDAR_URL = `${SITE_ORIGIN}/acnew`;
const CACHE_TTL_MS = 5 * 60_000;

export interface CollegeAnnouncement {
  id: string;
  title: string;
  url: string;
  source: string;
}

export interface CollegeEvent {
  id: string;
  title: string;
  url: string;
  details: string;
  department?: string;
  dateLabel?: string;
  location?: string;
}

export interface AcademicCalendarEntry {
  dateLabel: string;
  event: string;
  dayOrder?: string;
}

export interface CollegeUpdates {
  announcements: CollegeAnnouncement[];
  events: CollegeEvent[];
  calendar: {
    month: string;
    entries: AcademicCalendarEntry[];
    sourceUrl: string;
  };
  sources: {
    homepage: string;
    calendar: string;
  };
  fetchedAt: string;
}

type CachedUpdates = { expiresAt: number; value: CollegeUpdates };

let cache: CachedUpdates | null = null;
let inFlight: Promise<CollegeUpdates> | null = null;

const http = axios.create({
  timeout: 15_000,
  headers: {
    "User-Agent": "LoyolaStudentApp/1.0 (+https://github.com/Joerakesh/loyola-app)",
    Accept: "text/html,application/xhtml+xml",
  },
  maxRedirects: 5,
});

function clean(value: string): string {
  return value.replace(/\s+/g, " ").trim();
}

function absoluteUrl(href: string): string {
  try {
    const url = new URL(href, SITE_ORIGIN);
    return url.protocol === "http:" || url.protocol === "https:"
      ? url.toString()
      : SITE_ORIGIN;
  } catch {
    return SITE_ORIGIN;
  }
}

function stableId(url: string, title: string): string {
  return Buffer.from(`${url}| ${title}`).toString("base64url").slice(0, 32);
}

function scrapeAnnouncements($: cheerio.CheerioAPI): CollegeAnnouncement[] {
  const section = $('section[aria-label*="Events and announcements" i]').first();
  const scope = section.length ? section : $("body");
  const seen = new Set<string>();

  return scope.find("h6 a[href]").toArray().flatMap((node) => {
    const link = $(node);
    const title = clean(link.text());
    const href = link.attr("href");
    if (!title || !href || href.startsWith("#")) return [];

    const url = absoluteUrl(href);
    if (seen.has(url)) return [];
    seen.add(url);

    return [{
      id: stableId(url, title),
      title,
      url,
      source: "Loyola College",
    }];
  });
}

function scrapeEvents($: cheerio.CheerioAPI): CollegeEvent[] {
  const section = $('section[aria-label*="Events and announcements" i]').first();
  const scope = section.length ? section : $("body");
  const seen = new Set<string>();

  return scope.find("h3 a[href]").toArray().flatMap((node) => {
    const link = $(node);
    const title = clean(link.text());
    const href = link.attr("href");
    if (!title || !href || href.startsWith("#")) return [];

    const url = absoluteUrl(href);
    if (seen.has(url)) return [];
    seen.add(url);

    const card = link.closest("article").length
      ? link.closest("article")
      : link.parent().parent();
    const details = clean(card.text()).replace(title, "").trim();
    const lines = card.text().split(/\n+/).map(clean).filter(Boolean);
    const dateLabel = lines.find((line) =>
      /\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{1,2}/i.test(line),
    );
    const department = lines.find((line) =>
      /department|institute|centre|center|college|school/i.test(line),
    );
    const location = lines.find((line) =>
      /hall|room|block|auditorium|campus|lab/i.test(line),
    );

    return [{
      id: stableId(url, title),
      title,
      url,
      details,
      ...(department ? { department } : {}),
      ...(dateLabel ? { dateLabel } : {}),
      ...(location ? { location } : {}),
    }];
  });
}

function scrapeCalendar($: cheerio.CheerioAPI): CollegeUpdates["calendar"] {
  const month = clean(
    $("h1, h2, h3, h4")
      .toArray()
      .map((node) => clean($(node).text()))
      .find((text) =>
        /^(January|February|March|April|May|June|July|August|September|October|November|December)\s+20\d{2}$/i.test(text),
      ) ?? "",
  );

  const entries: AcademicCalendarEntry[] = [];
  const seen = new Set<string>();

  $("table tr").each((_, row) => {
    const cells = $(row).find("th, td").toArray().map((cell) => clean($(cell).text()));
    if (cells.length < 2) return;

    const dateLabel = cells[0] ?? "";
    const event = cells[1] ?? "";
    const dayOrderCell = cells[2] ?? "";
    if (!dateLabel || /^date$/i.test(dateLabel) || !/\d/.test(dateLabel)) return;

    const key = `${dateLabel}| ${event}| ${dayOrderCell}`;
    if (seen.has(key)) return;
    seen.add(key);

    entries.push({
      dateLabel,
      event,
      ...(dayOrderCell && /day\s*[- ]?\d+/i.test(dayOrderCell)
        ? { dayOrder: dayOrderCell.match(/day\s*[- ]?\d+/i)?.[0] }
        : {}),
    });
  });

  // Some calendar layouts expose their day cells as data attributes instead
  // of a table. Keep this fallback deliberately conservative.
  if (entries.length === 0) {
    $("[data-date]").each((_, node) => {
      const dateLabel = clean($(node).attr("data-date") ?? "");
      const event = clean($(node).find("[class*='event'], [class*='title']").text());
      const dayOrder = clean($(node).find("[class*='day-order']").text());
      if (!dateLabel) return;
      entries.push({
        dateLabel,
        event,
        ...(dayOrder ? { dayOrder } : {}),
      });
    });
  }

  return {
    month,
    entries,
    sourceUrl: CALENDAR_URL,
  };
}

async function fetchHtml(url: string): Promise<string> {
  const response = await http.get<string>(url, {
    responseType: "text",
    transformResponse: [(data) => data],
  });
  return response.data;
}

async function scrape(): Promise<CollegeUpdates> {
  const [homeHtml, calendarHtml] = await Promise.all([
    fetchHtml(HOME_URL),
    fetchHtml(CALENDAR_URL),
  ]);

  const home = cheerio.load(homeHtml);
  const calendarPage = cheerio.load(calendarHtml);

  return {
    announcements: scrapeAnnouncements(home),
    events: scrapeEvents(home),
    calendar: scrapeCalendar(calendarPage),
    sources: {
      homepage: HOME_URL,
      calendar: CALENDAR_URL,
    },
    fetchedAt: new Date().toISOString(),
  };
}

export class CollegeSiteService {
  async getUpdates(options: { refresh?: boolean } = {}): Promise<CollegeUpdates> {
    if (!options.refresh && cache && cache.expiresAt > Date.now()) {
      return cache.value;
    }

    if (!options.refresh && inFlight) return inFlight;

    inFlight = scrape()
      .then((value) => {
        cache = { value, expiresAt: Date.now() + CACHE_TTL_MS };
        return value;
      })
      .finally(() => {
        inFlight = null;
      });

    return inFlight;
  }
}

export const collegeSiteService = new CollegeSiteService();
