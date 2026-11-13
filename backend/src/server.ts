import "dotenv/config";

import express from "express";
import cors from "cors";
import helmet from "helmet";
import rateLimit from "express-rate-limit";
import { readFileSync } from "node:fs";

import attendanceRoutes from "./routes/attendance.routes.js";
import marksRoutes from "./routes/marks.routes.js";
import subjectsRoutes from "./routes/subjects.routes.js";
import studentRoutes from "./routes/student.routes.js";
import dashboardRoutes from "./routes/dashboard.routes.js";
import authRoutes from "./routes/auth.routes.js";
import homeRoutes from "./routes/home.routes.js";
import reflectionsRoutes from "./routes/reflections.routes.js";
import v2Routes from "./routes/v2.routes.js";
import collegeRoutes from "./routes/college.routes.js";
import { createPlatformRouter } from "./routes/platform.routes.js";
import { platformControllers } from "./controllers/platform.controllers.js";

const app = express();

// Vercel terminates the public connection and forwards requests with
// X-Forwarded-For. Trust only the nearest proxy so Express can safely resolve
// the client IP used by express-rate-limit.
app.set("trust proxy", 1);

app.use(
  helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        scriptSrc: ["'self'", "'unsafe-inline'", "https://unpkg.com"],
        styleSrc: ["'self'", "'unsafe-inline'", "https://unpkg.com"],
        imgSrc: ["'self'", "data:", "https:"],
        connectSrc: ["'self'"],
      },
    },
  }),
);

// Log every request with its final status and duration. Query strings, headers,
// and bodies are intentionally omitted because they can contain student data
// or credentials.
app.use((req, res, next) => {
  const startedAt = process.hrtime.bigint();

  res.on("finish", () => {
    const durationMs = Number(process.hrtime.bigint() - startedAt) / 1_000_000;
    console.log(
      `[HTTP] ${req.method} ${req.originalUrl.split("?", 1)[0]} ${res.statusCode} ${durationMs.toFixed(1)}ms`,
    );
  });

  next();
});

// CORS_ORIGINS="https://your-web-app.vercel.app,http://localhost:3000"
// Left unset it stays open, which is what the native mobile app needs anyway
// (it does not use CORS); set it in production to lock the browser origin down.
const allowedOrigins = process.env.CORS_ORIGINS?.split(",")
  .map((origin) => origin.trim())
  .filter(Boolean);

app.use(
  cors({
    origin: allowedOrigins?.length ? allowedOrigins : "*",
  }),
);

app.use(express.json({ limit: "1mb" }));
app.use(express.urlencoded({ extended: true, limit: "1mb" }));

// Students on campus Wi-Fi share one public IP, and a screen can make several
// requests, so the general limit is generous. Sign-in and ERP linking get a much
// tighter limit because they are the brute-force targets.
app.use(
  rateLimit({
    windowMs: 60 * 1000,
    limit: 600,
    standardHeaders: true,
    legacyHeaders: false,
  }),
);

app.use(
  "/api/v1/auth",
  rateLimit({
    windowMs: 60 * 1000,
    limit: 30,
    standardHeaders: true,
    legacyHeaders: false,
  }),
);

app.use("/api/v1/attendance", attendanceRoutes);
app.use("/api/v1/marks", marksRoutes);
app.use("/api/v1/subjects", subjectsRoutes);
app.use("/api/v1/student", studentRoutes);
app.use("/api/v1/dashboard", dashboardRoutes);
app.use("/api/v1/auth", authRoutes);
app.use("/api/v1/home", homeRoutes);
app.use("/api/v1/reflections", reflectionsRoutes);
app.use("/api/v2", v2Routes);
app.use("/api/v1/college", collegeRoutes);

app.use(
  "/api/v1/schedules",
  createPlatformRouter(platformControllers.schedules),
);
app.use(
  "/api/v1/announcements",
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

// Interactive Swagger UI and its machine-readable OpenAPI document.
const apiDocsHtml = readFileSync(new URL("./docs/api-docs.html", import.meta.url), "utf8");
const openApiDocument = JSON.parse(
  readFileSync(new URL("./docs/openapi.json", import.meta.url), "utf8"),
);
app.get("/api/docs", (_req, res) => res.type("html").send(apiDocsHtml));
app.get("/api/openapi.json", (_req, res) => res.json(openApiDocument));

app.get("/api/health", (_req, res) => {
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
  });
}

if (
  process.env.NODE_ENV !== "production" &&
  process.env.NODE_ENV !== "test"
) {
  start().catch((error) => {
    console.error("Failed to start backend:", error);
    process.exit(1);
  });
}

export default app;
