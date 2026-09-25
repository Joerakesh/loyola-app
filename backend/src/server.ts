import "dotenv/config";

import express from "express";
import cors from "cors";
import helmet from "helmet";
import rateLimit from "express-rate-limit";

import attendanceRoutes from "./routes/attendance.routes.js";
import marksRoutes from "./routes/marks.routes.js";
import subjectsRoutes from "./routes/subjects.routes.js";
import studentRoutes from "./routes/student.routes.js";
import dashboardRoutes from "./routes/dashboard.routes.js";
import bootstrapRoutes from "./routes/bootstrap.routes.js";
import authRoutes from "./routes/auth.routes.js";
import { createPlatformRouter } from "./routes/platform.routes.js";
import { createWebsiteRouter } from "./routes/website.routes.js";
import { createCalendarRouter } from "./routes/calendar.routes.js";
import { platformControllers } from "./controllers/platform.controllers.js";
import { websiteController } from "./controllers/website.controller.js";
import { calendarService } from "./services/calendar.service.js";

const app = express();

app.use(helmet());

app.use(
  cors({
    origin: "*",
  }),
);

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use(
  rateLimit({
    windowMs: 60 * 1000,
    limit: 100,
  }),
);

app.use("/api/v1/attendance", attendanceRoutes);
app.use("/api/v1/marks", marksRoutes);
app.use("/api/v1/subjects", subjectsRoutes);
app.use("/api/v1/student", studentRoutes);
app.use("/api/v1/dashboard", dashboardRoutes);

// Single home-screen load: student + attendance + announcements in one call.
app.use("/api/v1/bootstrap", bootstrapRoutes);

app.use("/api/v1/auth", authRoutes);

app.use(
  "/api/v1/schedules",
  createPlatformRouter(platformControllers.schedules),
);
app.use(
  "/api/v1/user/announcements",
  createPlatformRouter(platformControllers.announcements),
);
app.use(
  "/api/v1/assignments",
  createPlatformRouter(platformControllers.assignments),
);
app.use(
  "/api/v1/reminders",
  createPlatformRouter(platformControllers.reminders),
);
app.use(
  "/api/v1/notifications",
  createPlatformRouter(platformControllers.notifications),
);

// Scraped public college-website content. `/api/v1/announcements` is the
// friendly public alias the app's Announcements screen uses; the platform CRUD
// for a user's own announcements lives at `/api/v1/user/announcements`.
app.use("/api/v1/website", createWebsiteRouter());
app.get(
  "/api/v1/announcements",
  websiteController.listAnnouncements.bind(websiteController),
);

app.use("/api/v1/calendar", createCalendarRouter());

app.get("/api/health", (_req, res) => {
  console.log("req came from", _req.originalUrl);
  res.json({
    status: "ok",
    service: "college-mobile-backend",
    version: "v2-lazy-boot",
  });
});

const PORT = Number(process.env.PORT ?? 3000);

async function start() {
  app.listen(PORT, () => {
    console.log(`Backend running on http://localhost:${PORT}`);

    // Periodic MongoDB sync of the college academic calendar.
    calendarService.start();
  });
}

if (process.env.NODE_ENV !== "production") {
  start().catch((error) => {
    console.error("Failed to start backend:", error);
    process.exit(1);
  });
}

export default app;