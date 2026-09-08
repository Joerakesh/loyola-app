import "dotenv/config";
import app from "./app.js";
import { connectMongo } from "./config/mongo.js";
import { userRepository } from "./repositories/user.repository.js";
import { platformControllers } from "./controllers/platform.controllers.js";

const PORT = Number(process.env.PORT);

async function main() {
  await connectMongo();
  await userRepository.ensureIndexes();
  await Promise.all(
    Object.values(platformControllers).map((controller) =>
      controller.ensureIndexes(),
    ),
  );

  app.listen(PORT, () => {
    console.log(`Backend running on http://localhost:${PORT}`);
  });
}

main().catch((error) => {
  console.error("Failed to start backend:", error);
  process.exit(1);
});

// export default app;