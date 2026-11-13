import { Router } from "express";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireAdmin } from "../middleware/admin.middleware.js";
import adminConsoleHtml from "../admin/admin-console.js";

const router = Router();

router.get("/console", (_req, res) => res.type("html").send(adminConsoleHtml));

router.get("/overview", requireAuth, requireAdmin, (req, res) => {
  const email = String(res.locals.user?.email ?? "");
  return res.json({
    status: "success",
    admin: { email },
    service: { name: "Loyola Student API", status: "available" },
    generatedAt: new Date().toISOString(),
  });
});

export default router;
