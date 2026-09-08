import { Router } from "express";
import { marksController } from "../controllers/marks.controller.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireErpClient } from "../middleware/lrms-bridge.middleware.js";

const router = Router();

router.get(
  "/internal",
  requireAuth,
  requireErpClient,
  marksController.internal.bind(marksController),
);
export default router;
