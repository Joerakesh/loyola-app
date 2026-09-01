import { Request, Response } from "express";
import { DashboardService } from "../services/dashboard.service.js";

export class DashboardController {
  async getDashboard(req: Request, res: Response) {
    try {
      const client = res.locals.lrmsClient;

      const service = new DashboardService(client);

      const data = await service.getDashboard();

      return res.json({
        status: "success",
        data,
      });
    } catch (error) {
      console.error("Dashboard error:", error);

      return res.status(502).json({
        status: "error",
        message: "Unable to fetch dashboard",
      });
    }
  }
}

export const dashboardController = new DashboardController();
