import { Router } from "express";
import { dashboardController } from "../controllers/dashboard.controller.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireErpClient } from "../middleware/lrms-bridge.middleware.js";

const router = Router();

router.get(
  "/",
  requireAuth,
  requireErpClient,
  dashboardController.getDashboard.bind(dashboardController),
);

export default router;
