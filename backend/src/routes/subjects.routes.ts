import { Router } from "express";
import { subjectsController } from "../controllers/subjects.controller.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { responseCache } from "../middleware/response-cache.middleware.js";
import { requireErpClient } from "../middleware/lrms-bridge.middleware.js";

const router = Router();

router.get(
  "/",
  requireAuth,
  responseCache("subjects"),
  requireErpClient,
  subjectsController.getSubjects.bind(subjectsController),
);
export default router;
