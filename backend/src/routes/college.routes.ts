import { Router } from "express";
import { collegeSiteController } from "../controllers/college-site.controller.js";
import { academicCalendarController } from "../controllers/academic-calendar.controller.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireAdmin } from "../middleware/admin.middleware.js";

const router = Router();

// Public institutional information; no student ERP session is required.
router.get("/updates", collegeSiteController.updates.bind(collegeSiteController));

// Public month-specific calendar. Data is served exclusively from MongoDB.
router.get("/calendar", academicCalendarController.month.bind(academicCalendarController));

// Explicit admin operation: scrape the academic year and archive changed months.
router.post(
  "/calendar/scrape",
  requireAuth,
  requireAdmin,
  academicCalendarController.scrapeAndStore.bind(academicCalendarController),
);

export default router;
