import { Router } from "express";
import { collegeSiteController } from "../controllers/college-site.controller.js";
import { academicCalendarController } from "../controllers/academic-calendar.controller.js";

const router = Router();

// Public institutional information; no student ERP session is required.
router.get("/updates", collegeSiteController.updates.bind(collegeSiteController));

// Public month-specific calendar. Data is served exclusively from MongoDB.
router.get("/calendar", academicCalendarController.month.bind(academicCalendarController));

// Public maintenance endpoint: scrape the academic year and archive changed months.
router.post(
  "/calendar/scrape",
  academicCalendarController.scrapeAndStore.bind(academicCalendarController),
);

export default router;
