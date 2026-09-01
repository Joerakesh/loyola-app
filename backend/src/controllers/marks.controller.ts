import { Request, Response } from "express";
import { MarksService } from "../services/marks.service.js";
import { StudentService } from "../services/student.service.js";

export class MarksController {
  async internal(req: Request, res: Response) {
    try {
      const client = res.locals.lrmsClient;

      const studentService = new StudentService(client);

      const profile = await studentService.getProfile();

      const marksService = new MarksService(client);

      const data = await marksService.getInternalMarks(profile.registerNumber);

      return res.json({
        status: "success",
        data,
      });
    } catch (error) {
      console.error("Internal marks error:", error);

      return res.status(502).json({
        status: "error",
        message: "Unable to fetch internal marks",
      });
    }
  }
}

export const marksController = new MarksController();
