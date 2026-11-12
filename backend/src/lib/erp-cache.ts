import { TtlCache } from "./ttl-cache.js";

export interface ApiBody {
  status: string;
  data: unknown;
}

/** Per-user cache of ERP-backed API responses. Keys look like `<userId>:<name>`. */
export const erpResponseCache = new TtlCache<ApiBody>(1000);

/**
 * How long each ERP-backed resource stays fresh. Attendance changes through the
 * day; subjects and profile almost never do.
 */
export const ERP_TTL_MS = {
  dashboard: 5 * 60_000,
  attendanceSummary: 2 * 60_000,
  attendanceHourly: 2 * 60_000,
  subjects: 30 * 60_000,
  profile: 30 * 60_000,
  marks: 5 * 60_000,
} as const;

export type ErpResource = keyof typeof ERP_TTL_MS;

export function erpCacheKey(userId: string, resource: ErpResource) {
  return `${userId}:${resource}`;
}

export function invalidateUserCache(userId: string) {
  erpResponseCache.deletePrefix(`${userId}:`);
}
