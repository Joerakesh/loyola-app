import { Router } from "express";

import { authController } from "../controllers/auth.controller.js";
import { requireAuth } from "../middleware/auth.middleware.js";
const router = Router();

router.post("/login", authController.login.bind(authController));
router.post("/logout", requireAuth, (req, res) =>
  authController.logout(req, res),
);

export default router;
