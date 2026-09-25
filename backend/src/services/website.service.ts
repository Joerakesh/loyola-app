import { WEBSITE_CONFIG } from "../config/website.js";
import {
  WebsiteAnnouncement,
  WebsiteClient,
} from "../upstream/website.client.js";

interface CacheEntry {
  data: WebsiteAnnouncement[];
  expiresAt: number;
}

/**
 * Serves public Loyola College website content to the API. Results are cached
 * in memory for WEBSITE_CACHE_TTL_SECONDS so we don't re-scrape the college's
 * (large) homepage on every request.
 */
export class WebsiteService {
  private readonly client = new WebsiteClient();
  private cache: CacheEntry | null = null;

  async getAnnouncements(): Promise<WebsiteAnnouncement[]> {
    const now = Date.now();

    if (this.cache && now < this.cache.expiresAt) {
      return this.cache.data;
    }

    const data = await this.client.getAnnouncements();

    this.cache = {
      data,
      expiresAt: now + WEBSITE_CONFIG.cacheTtlSeconds * 1000,
    };

    return data;
  }
}

export const websiteService = new WebsiteService();