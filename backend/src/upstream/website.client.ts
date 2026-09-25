import axios from "axios";
import * as cheerio from "cheerio";
import { createHash } from "node:crypto";

import { WEBSITE_CONFIG } from "../config/website.js";

export interface WebsiteAnnouncementAttachment {
  url: string;
  filename: string;
  type: "pdf" | "image" | "file";
}

export interface WebsiteAnnouncement {
  id: string;
  title: string;
  /** Absolute link the announcement points to. */
  url: string;
  /** Populated when the link is a downloadable file (e.g. a PDF circular). */
  attachment: WebsiteAnnouncementAttachment | null;
}

/**
 * Fetches and parses public content from the Loyola College website.
 */
export class WebsiteClient {
  private readonly client;

  constructor() {
    this.client = axios.create({
      baseURL: WEBSITE_CONFIG.baseUrl,
      timeout: 15_000,
      headers: {
        "User-Agent": "Mozilla/5.0 (compatible; CollegeMobileApp/1.0)",
        Accept: "text/html",
      },
    });
  }

  /**
   * Parses the "Announcements" section of the homepage:
   *
   *   <div class="announcement-item">
   *     <span class="announcement-bullet"></span>
   *     <h6><a href="../../announcements/<hash>.pdf">Title</a></h6>
   *   </div>
   */
  async getAnnouncements(): Promise<WebsiteAnnouncement[]> {
    const response = await this.client.get<string>(WEBSITE_CONFIG.paths.home);
    const $ = cheerio.load(response.data);

    const seen = new Set<string>();
    const items: WebsiteAnnouncement[] = [];

    $(".announcement-item").each((_index, element) => {
      const $item = $(element);
      const $link = $item.find("a").first();

      const title = $link.text().replace(/\s+/g, " ").trim();
      const href = $link.attr("href");

      if (!title || !href) {
        return;
      }

      const url = new URL(href, WEBSITE_CONFIG.baseUrl).toString();

      // The homepage repeats the same items for its seamless-scroll loop —
      // keep one entry per unique announcement.
      if (seen.has(url)) {
        return;
      }
      seen.add(url);

      items.push({
        id: createHash("sha1").update(url).digest("hex").slice(0, 16),
        title,
        url,
        attachment: this.describeAttachment(href, url),
      });
    });

    return items;
  }

  private describeAttachment(
    href: string,
    url: string,
  ): WebsiteAnnouncementAttachment | null {
    const lower = href.toLowerCase();

    if (
      !lower.endsWith(".pdf") &&
      !/\.(png|jpe?g|gif|webp|svg|bmp|tiff?)$/.test(lower) &&
      !lower.includes(".")
    ) {
      // Looks like a regular in-site page, not a downloadable file.
      return null;
    }

    const isPdf = lower.endsWith(".pdf");
    const isImage = /\.(png|jpe?g|gif|webp|svg|bmp|tiff?)$/.test(lower);

    const rawName = url.split("/").pop() ?? "";
    const filename = decodeURIComponent(rawName.split("?")[0]) || "attachment";

    return {
      url,
      filename,
      type: isPdf ? "pdf" : isImage ? "image" : "file",
    };
  }
}