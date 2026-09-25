import { Router } from "express";

import { websiteController } from "../controllers/website.controller.js";

/**
 * Public routes for content scraped from the college website.
 *
 * Unlike the platform CRUD resources, these are intentionally left
 * unauthenticated — the source data is the college's own public site. The
 * global rate limiter still applies.
 */
export function createWebsiteRouter(): Router {
  const router = Router();

  router.get(
    "/announcements",
    websiteController.listAnnouncements.bind(websiteController),
  );

  return router;
}