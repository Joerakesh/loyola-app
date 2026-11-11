import { Router } from "express";
import { attendanceController } from "../controllers/attendance.controller.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { responseCache } from "../middleware/response-cache.middleware.js";
import { requireErpClient } from "../middleware/lrms-bridge.middleware.js";

const router = Router();

router.get(
  "/summary",
  requireAuth,
  responseCache("attendanceSummary"),
  requireErpClient,
  attendanceController.summary.bind(attendanceController),
);

router.get(
  "/hourly",
  requireAuth,
  responseCache("attendanceHourly"),
  requireErpClient,
  attendanceController.hourly.bind(attendanceController),
);

export default router;
