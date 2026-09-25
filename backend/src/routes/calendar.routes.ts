import { Router } from "express";

import { calendarController } from "../controllers/calendar.controller.js";

/**
 * Public read-only routes for the college academic calendar (Mongo-backed,
 * auto-synced from loyolacollege.edu/acnew.php).
 */
export function createCalendarRouter(): Router {
  const router = Router();

  router.get("/", calendarController.list.bind(calendarController));

  return router;
}