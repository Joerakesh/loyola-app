import { Request, Response } from "express";
import { MarksService } from "../services/marks.service.js";
import { StudentService } from "../services/student.service.js";
import {
  ERP_TTL_MS,
  erpCacheKey,
  erpResponseCache,
} from "../lib/erp-cache.js";

export class MarksController {
  async internal(req: Request, res: Response) {
    try {
      const client = res.locals.lrmsClient;

      const studentService = new StudentService(client);

      // Reuse the profile cached by GET /student/profile when it is fresh.
      const profileBody = await erpResponseCache.readThrough(
        erpCacheKey(res.locals.user.id, "profile"),
        ERP_TTL_MS.profile,
        async () => ({
          status: "success",
          data: await studentService.getProfile(),
        }),
      );
      const profile = profileBody.data as { studentId: string };

      const marksService = new MarksService(client);

      const data = await marksService.getInternalMarks(profile.studentId);

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
