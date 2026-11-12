import { Request, Response } from "express";
import { StudentService } from "../services/student.service.js";

export class StudentController {
  async photo(_req: Request, res: Response) {
    try {
      const client = res.locals.lrmsClient;
      const response = await client.getHtml("/dashboard.jsp");

      const html = response.data;
      const imageElement = html.match(
        /<img\b[^>]*(?:id|name)=["']studentPhoto["'][^>]*>/i,
      )?.[0];
      const imageSource = imageElement?.match(
        /src=["']([^"']+)["']/i,
      )?.[1];

      // The ERP page assigns the student's Base64 photo to imageDataUri and
      // then sets it on #studentPhoto. Support either representation.
      const embeddedPhoto = html.match(
        /data:image\/[a-zA-Z0-9.+-]+;base64,[A-Za-z0-9+/=\r\n]+/,
      )?.[0];

      const photoDataUri = [imageSource, embeddedPhoto]
        .map((value) => value?.replace(/\s/g, "").trim())
        .find((value) => value?.startsWith("data:image/"));

      if (!photoDataUri) {
        return res.status(404).json({
          status: "error",
          message: "Student photo is not available in the ERP session",
        });
      }

      return res.json({
        status: "success",
        data: { photoDataUri },
      });
    } catch (error) {
      console.error("Student photo error:", error);
      return res.status(502).json({
        status: "error",
        message: "Unable to fetch student photo from Loyola ERP",
      });
    }
  }

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
