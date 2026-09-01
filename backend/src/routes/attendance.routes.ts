import { Router } from "express";
import { attendanceController } from "../controllers/attendance.controller.js";
import { requireAuth } from "../middleware/auth.middleware.js";

const router = Router();

router.get(
  "/summary",
  requireAuth,
  attendanceController.summary.bind(attendanceController),
);

router.get(
  "/hourly",
  requireAuth,
  attendanceController.hourly.bind(attendanceController),
);

export default router;
