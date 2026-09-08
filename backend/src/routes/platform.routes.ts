import { Router } from "express";

import { requireAuth } from "../middleware/auth.middleware.js";
import { PlatformController } from "../controllers/platform.controller.js";

export function createPlatformRouter(controller: PlatformController): Router {
  const router = Router();
  const options = controller.options;

  router.get(
    "/",
    requireAuth,
    controller.list.bind(controller),
  );

  router.post(
    "/",
    requireAuth,
    controller.create.bind(controller),
  );

  router.get(
    "/:id",
    requireAuth,
    controller.get.bind(controller),
  );

  router.patch(
    "/:id",
    requireAuth,
    controller.update.bind(controller),
  );

  if (options.read) {
    router.post(
      "/:id/read",
      requireAuth,
      controller.markRead.bind(controller),
    );
  }

  if (options.done) {
    router.post(
      "/:id/done",
      requireAuth,
      controller.markDone.bind(controller),
    );
  }

  router.delete(
    "/:id",
    requireAuth,
    controller.remove.bind(controller),
  );

  return router;
}