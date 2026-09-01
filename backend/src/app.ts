import express from "express";
import cors from "cors";
import helmet from "helmet";
import rateLimit from "express-rate-limit";

// routes import
import attendanceRoutes from "./routes/attendance.routes.js";
import marksRoutes from "./routes/marks.routes.js";
import subjectsRoutes from "./routes/subjects.routes.js";
import studentRoutes from "./routes/student.routes.js";
import dashboardRoutes from "./routes/dashboard.routes.js";
import authRoutes from "./routes/auth.routes.js";

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

// routes
app.use("/api/v1/attendance", attendanceRoutes);
app.use("/api/v1/marks", marksRoutes);
app.use("/api/v1/subjects", subjectsRoutes);
app.use("/api/v1/student", studentRoutes);
app.use("/api/v1/dashboard", dashboardRoutes);
app.use("/api/v1/auth", authRoutes);

app.get("/api/health", (_req, res) => {
  console.log("req came from", _req.originalUrl);
  res.json({
    status: "ok",
    service: "college-mobile-backend",
  });
});

export default app;
