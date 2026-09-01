import { Router } from "express";
import { subjectsController } from "../controllers/subjects.controller.js";
import { requireAuth } from "../middleware/auth.middleware.js";

const router = Router();

router.get(
  "/",
  requireAuth,
  subjectsController.getSubjects.bind(subjectsController),
);
export default router;
