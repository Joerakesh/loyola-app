import { userRepository } from "../repositories/user.repository.js";
import { erpSessionRepository } from "../repositories/erp-session.repository.js";
import { platformControllers } from "../controllers/platform.controllers.js";

let pending: Promise<void> | null = null;

/**
 * Creates the MongoDB indexes once per server instance. ensureIndexes() existed
 * on every repository but was never called, so queries by googleId, email and
 * userId were full collection scans.
 *
 * Fire-and-forget: a failure is logged, never blocks or breaks a request.
 */
export function ensureIndexesOnce(): Promise<void> {
  if (!pending) {
    pending = Promise.all([
      userRepository.ensureIndexes(),
      erpSessionRepository.ensureIndexes(),
      ...Object.values(platformControllers).map((controller) =>
        controller.ensureIndexes(),
      ),
    ])
      .then(() => undefined)
      .catch((error: unknown) => {
        console.error(
          "Index creation failed:",
          error instanceof Error ? error.message : error,
        );
      });
  }

  return pending;
}
