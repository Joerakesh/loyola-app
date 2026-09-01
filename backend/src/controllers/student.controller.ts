import { Request, Response } from "express";
import { lrmsSessionService } from "../services/lrms-session.service.js";
import { StudentService } from "../services/student.service.js";

export class StudentController {
  async profile(req: Request, res: Response) {
    try {
      const client = res.locals.lrmsClient;

      const service = new StudentService(client);

      const data = await service.getProfile();

      return res.json({
        status: "success",
        data,
      });
    } catch (error) {
      console.error("Student profile error:", error);

      return res.status(502).json({
        status: "error",
        message: "Unable to fetch student profile",
      });
    }
  }
}

export const studentController = new StudentController();
