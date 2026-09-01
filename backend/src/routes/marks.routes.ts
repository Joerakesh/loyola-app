import { Router } from "express";
import { marksController } from "../controllers/marks.controller.js";
import { requireAuth } from "../middleware/auth.middleware.js";

const router = Router();

router.get(
  "/internal",
  requireAuth,
  marksController.internal.bind(marksController),
);
export default router;
