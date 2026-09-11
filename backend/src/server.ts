import "dotenv/config";

import app from "./lib/app.js";

const PORT = Number(process.env.PORT ?? 3000);

async function start() {
  app.listen(PORT, () => {
    console.log(`Backend running on http://localhost:${PORT}`);
  });
}

if (process.env.NODE_ENV !== "production") {
  start().catch((error) => {
    console.error("Failed to start backend:", error);
    process.exit(1);
  });
}

export default app;