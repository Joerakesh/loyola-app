/**
 * Config for the Loyola College academic calendar scraper + sync.
 *
 * The college site's `acnew.php?action=list_next&year=Y&month=M` page displays
 * month M+1, so the sync requests month M-1 to obtain month M.
 */
export const CALENDAR_CONFIG = {
  baseUrl:
    process.env.CALENDAR_BASE_URL ??
    "https://www.loyolacollege.edu/acnew.php",

  /** Mongo collection that stores one document per calendar month. */
  collectionName: "calendar_months",

  /** Sync window around the current month (inclusive). */
  monthsBefore: Number(process.env.CALENDAR_SYNC_MONTHS_BEFORE ?? 2),
  monthsAfter: Number(process.env.CALENDAR_SYNC_MONTHS_AFTER ?? 10),

  /**
   * A stored month older than this (seconds) is re-fetched in the background
   * when it is read, so late edits on the college site propagate.
   */
  staleAfterSeconds: Number(
    process.env.CALENDAR_STALE_AFTER_SECONDS ?? 6 * 3600,
  ),

  /** How often the periodic full-window sync runs (minutes). */
  syncIntervalMinutes: Number(
    process.env.CALENDAR_SYNC_INTERVAL_MINUTES ?? 6 * 60,
  ),

  /** HTTP timeout for one calendar page fetch (ms). */
  fetchTimeoutMs: Number(process.env.CALENDAR_FETCH_TIMEOUT_MS ?? 20_000),
} as const;