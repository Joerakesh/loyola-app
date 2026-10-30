import app from "../backend/src/server.js";

// Vercel routes every /api/* request through this catch-all function.
// Express keeps ownership of the complete /api/v1 route tree.
export default app;
