// import "dotenv/config";
// import app from "./app.js";
import express from "express";

const app = express();

// only for testing
app.get("/api/health", (_req, res) => {
  res.json({
    status: "ok",
    version: "test",
  });
});

export default app;

// const PORT = Number(process.env.PORT ?? 3000);

// async function start() {
//   app.listen(PORT, () => {
//     console.log(`Backend running on http://localhost:${PORT}`);
//   });
// }

// if (process.env.NODE_ENV !== "production") {
//   start().catch((error) => {
//     console.error("Failed to start backend:", error);
//     process.exit(1);
//   });
// }
