import { Request, Response } from "express";
import { SubjectsService } from "../services/subjects.service.js";

export class SubjectsController {
  async getSubjects(req: Request, res: Response) {
    try {
      const client = res.locals.lrmsClient;

      const service = new SubjectsService(client);

      const data = await service.getSubjects();

      return res.json({
        status: "success",
        data,
      });
    } catch (error) {
      console.error("Subjects error:", error);

      return res.status(502).json({
        status: "error",
        message: "Unable to fetch subjects",
      });
    }
  }
}

export const subjectsController = new SubjectsController();
