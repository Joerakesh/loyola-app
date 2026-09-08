import { Router } from "express";
import { attendanceController } from "../controllers/attendance.controller.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireErpClient } from "../middleware/lrms-bridge.middleware.js";

const router = Router();

router.get(
  "/summary",
  requireAuth,
  requireErpClient,
  attendanceController.summary.bind(attendanceController),
);

router.get(
  "/hourly",
  requireAuth,
  requireErpClient,
  attendanceController.hourly.bind(attendanceController),
);

export default router;
