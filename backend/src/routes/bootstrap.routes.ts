import { Router } from "express";

import { bootstrapController } from "../controllers/bootstrap.controller.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireErpClient } from "../middleware/lrms-bridge.middleware.js";

const router = Router();

/**
 * GET /api/v1/bootstrap — single call that loads everything the home screen
 * needs after login: student profile + fees, attendance summary, the 6 most
 * recent class days, and the current college announcements. One authenticated
 * LRMS session is reused (cached) for the whole request.
 */
router.get(
  "/",
  requireAuth,
  requireErpClient,
  bootstrapController.index.bind(bootstrapController),
);

export default router;