import { Router } from "express";
import { portalV2Controller } from "../controllers/portal-v2.controller.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireErpClient } from "../middleware/lrms-bridge.middleware.js";

const router = Router();
router.get("/", (_req, res) => res.json({
  status: "ok",
  version: "v2",
  portalSections: ["profile", "dashboard", "attendance", "academics", "fees", "registrations"],
  platformCollections: ["assignments", "announcements", "schedules", "reminders", "notifications"],
}));
router.get("/platform/:collection", requireAuth, portalV2Controller.listPlatform.bind(portalV2Controller));
router.get("/portal", requireAuth, requireErpClient, portalV2Controller.get.bind(portalV2Controller));
router.get("/portal/:section", requireAuth, requireErpClient, portalV2Controller.get.bind(portalV2Controller));
router.post("/portal/credentials", requireAuth, portalV2Controller.syncPassword.bind(portalV2Controller));
router.put("/portal/password", requireAuth, requireErpClient, portalV2Controller.changePassword.bind(portalV2Controller));

export default router;
