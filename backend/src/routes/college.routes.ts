import { Router } from "express";
import { collegeSiteController } from "../controllers/college-site.controller.js";
import { academicCalendarController } from "../controllers/academic-calendar.controller.js";

const router = Router();

// Public institutional information; no student ERP session is required.
router.get("/updates", collegeSiteController.updates.bind(collegeSiteController));
router.get("/calendar", academicCalendarController.month.bind(academicCalendarController));

export default router;
