import { Router } from "express";
import { collegeSiteController } from "../controllers/college-site.controller.js";

const router = Router();

// Public institutional information; no student ERP session is required.
router.get("/updates", collegeSiteController.updates.bind(collegeSiteController));

export default router;
