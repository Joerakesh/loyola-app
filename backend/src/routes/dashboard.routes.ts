import { Router } from "express";
import { dashboardController } from "../controllers/dashboard.controller.js";
import { requireAuth } from "../middleware/auth.middleware.js";

const router = Router();

router.get(
  "/",
  requireAuth,
  dashboardController.getDashboard.bind(dashboardController),
);

export default router;
