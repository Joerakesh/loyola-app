import { Router } from "express";

import { authController } from "../controllers/auth.controller.js";
import { requireAuth } from "../middleware/auth.middleware.js";
const router = Router();

router.post("/google", (req, res) => authController.googleLogin(req, res));
router.get("/google/me", requireAuth, (req, res) => authController.me(req, res));
router.post("/refresh", requireAuth, (req, res) =>
  authController.refresh(req, res),
);
router.post("/logout", requireAuth, (req, res) =>
  authController.logout(req, res),
);
router.post("/bind-erp", requireAuth, (req, res) =>
  authController.bindErp(req, res),
);
router.post("/bind-email", requireAuth, (req, res) =>
  authController.bindEmail(req, res),
);
router.post("/unbind-erp", requireAuth, (req, res) =>
  authController.unbindErp(req, res),
);

export default router;