import { Router } from "express";
import { LRMSClient } from "../upstream/lrms.client.js";

const router = Router();

router.post("/cookie-persistence", async (req, res) => {
  try {
    const { registrationNumber, password } = req.body;

    if (!registrationNumber || !password) {
      return res.status(400).json({
        status: "error",
        message: "registrationNumber and password are required",
      });
    }

    // =====================================================
    // STEP 1 — Create fresh LRMS client
    // =====================================================

    let client: LRMSClient | null = new LRMSClient();

    console.log("1. Created first LRMSClient");

    // =====================================================
    // STEP 2 — Fetch login page
    // =====================================================

    const loginPage = await client.getLoginPage();

    console.log("2. CAPTCHA obtained:", loginPage.captcha);

    // =====================================================
    // STEP 3 — Login
    // =====================================================

    const loginResult = await client.login(
      registrationNumber,
      password,
      loginPage.captcha,
    );

    console.log("3. Login result:", loginResult);

    if (!loginResult || loginResult.status !== "success") {
      throw new Error(loginResult?.message ?? "LRMS login failed");
    }

    // =====================================================
    // STEP 4 — Extract cookies
    // =====================================================

    const cookies = await client.getCookies();

    console.log("4. Saved cookies:", cookies);

    if (!cookies) {
      throw new Error("No cookies found after login");
    }

    // =====================================================
    // STEP 5 — DESTROY original client
    // =====================================================

    client = null;

    console.log("5. Original LRMSClient destroyed");

    // =====================================================
    // STEP 6 — Recreate client from cookies
    // =====================================================

    const restoredClient = await LRMSClient.fromCookies(cookies);

    console.log("6. New LRMSClient recreated from cookies");

    // =====================================================
    // STEP 7 — Call dashboard using NEW client
    // =====================================================

    const dashboard = await restoredClient.post(
      "/ajax/getStudentDashboard.jsp",
    );

    console.log("7. Dashboard response:", dashboard.data);

    return res.json({
      status: "success",
      message: "Cookie persistence test passed",
      dashboard: dashboard.data,
    });
  } catch (error: any) {
    console.error("COOKIE PERSISTENCE TEST FAILED");

    console.error("message:", error.message);

    console.error("status:", error.response?.status);

    console.error("response:", error.response?.data);

    return res.status(502).json({
      status: "error",
      message: "Cookie persistence test failed",
      debug: {
        message: error.message,
        upstreamStatus: error.response?.status,
      },
    });
  }
});

export default router;
