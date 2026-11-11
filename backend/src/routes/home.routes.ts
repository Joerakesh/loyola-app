import { Router } from "express";
import { homeController } from "../controllers/home.controller.js";
import { requireAuth } from "../middleware/auth.middleware.js";

const router = Router();

// No requireErpClient here: the controller builds the lazy client itself so
// users without a linked ERP still get their saved items and daily reflection.
router.get("/", requireAuth, homeController.get.bind(homeController));

export default router;
