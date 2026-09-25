/**
 * Config for scraping the public Loyola College website.
 */
export const WEBSITE_CONFIG = {
  baseUrl:
    process.env.WEBSITE_BASE_URL ?? "https://www.loyolacollege.edu",

  paths: {
    home: "/",
  },

  /**
   * The college homepage is a large page; cache parsed results in memory so
   * the app doesn't re-fetch it on every request. Override in .env.
   */
  cacheTtlSeconds: Number(process.env.WEBSITE_CACHE_TTL_SECONDS ?? 300),
} as const;