import { Router } from "express";
import { lrmsSessionService } from "../services/lrms-session.service.js";
import { LRMS_CONFIG } from "../config/lrms.js";

const router = Router();

router.get("/login-page", async (_req, res) => {
  try {
    const { sessionId, client } = lrmsSessionService.createSession();

    const result = await client.getLoginPage();

    res.json({
      status: "success",
      sessionId,
      captcha: result.captcha,
    });
  } catch (error) {
    console.error("LRMS login page error:", error);

    res.status(502).json({
      status: "error",
      message: "Unable to fetch LRMS login page",
    });
  }
});

router.post("/login", async (req, res) => {
  try {
    const { sessionId, registrationNumber, password, captcha } = req.body;

    if (!sessionId || !registrationNumber || !password || !captcha) {
      return res.status(400).json({
        status: "error",
        message: "Missing required fields",
      });
    }

    const client = lrmsSessionService.getSession(sessionId);

    const result = await client.login(registrationNumber, password, captcha);
    console.log("this is result of login req", result);
    res.json({
      status: "success",
      upstream: result,
    });
  } catch (error) {
    console.error("LRMS login error:", error);

    res.status(502).json({
      status: "error",
      message: "LRMS login failed",
    });
  }
});

router.get("/attendance", async (req, res) => {
  try {
    const sessionId = req.query.sessionId as string;

    if (!sessionId) {
      return res.status(400).json({
        status: "error",
        message: "sessionId is required",
      });
    }

    const client = lrmsSessionService.getSession(sessionId);

    const result = await client.post(LRMS_CONFIG.endpoints.attendanceSummary);

    console.log("LRMS attendance status:", result.status);
    console.log("LRMS attendance response:", result.data);

    res.json({
      status: "success",
      data: result.data,
    });
  } catch (error: any) {
    console.error("========== ATTENDANCE ERROR ==========");
    console.error("message:", error.message);
    console.error("status:", error.response?.status);
    console.error("response:", error.response?.data);
    console.error("======================================");

    res.status(502).json({
      status: "error",
      message: "Unable to fetch attendance",
      debug: {
        message: error.message,
        upstreamStatus: error.response?.status,
        upstreamResponse: error.response?.data,
      },
    });
  }
});

export default router;
