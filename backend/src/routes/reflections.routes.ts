import { Router } from "express";
import { requireAuth } from "../middleware/auth.middleware.js";
import { getReflectionForDate } from "../content/reflections.js";

const router = Router();

router.get("/today", requireAuth, (_req, res) => {
  res.setHeader("Cache-Control", "private, max-age=3600");
  res.json({ status: "success", data: getReflectionForDate() });
});

export default router;
