import { Request, Response } from "express";
import { AttendanceService } from "../services/attendance.service.js";

export class AttendanceController {
  async summary(req: Request, res: Response) {
    try {
      const client = res.locals.lrmsClient;

      const service = new AttendanceService(client);

      const data = await service.getSummary();

      return res.json({
        status: "success",
        data,
      });
    } catch (error) {
      console.error("Attendance summary error:", error);

      return res.status(502).json({
        status: "error",
        message: "Unable to fetch attendance summary",
      });
    }
  }

  async hourly(req: Request, res: Response) {
    try {
      const client = res.locals.lrmsClient;

      const service = new AttendanceService(client);

      const data = await service.getHourly();

      return res.json({
        status: "success",
        data,
      });
    } catch (error) {
      console.error("Hourly attendance error:", error);

      return res.status(502).json({
        status: "error",
        message: "Unable to fetch hourly attendance",
      });
    }
  }
}

export const attendanceController = new AttendanceController();
