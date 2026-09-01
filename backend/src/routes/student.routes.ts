import { Router } from "express";
import { studentController } from "../controllers/student.controller.js";
import { requireAuth } from "../middleware/auth.middleware.js";

const router = Router();
router.get(
  "/profile",
  requireAuth,
  studentController.profile.bind(studentController),
);
export default router;
