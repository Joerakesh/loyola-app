import { apiFetch } from "./client";
import type { AnnouncementsResponse } from "../../types/api";

/**
 * Public college-website announcements (GET /api/v1/announcements).
 * No auth token required — the endpoint scrapes loyolacollege.edu.
 */
export async function getAnnouncements(): Promise<AnnouncementsResponse> {
  return apiFetch<AnnouncementsResponse>("/announcements");
}