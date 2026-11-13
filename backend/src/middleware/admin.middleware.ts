import { Request, Response, NextFunction } from "express";

/**
 * Admin access is deliberately opt-in. Configure ADMIN_EMAILS with a
 * comma-separated allowlist of verified account emails. An empty allowlist
 * denies every admin request (fail closed).
 */
export function requireAdmin(_req: Request, res: Response, next: NextFunction) {
  const configured = (process.env.ADMIN_EMAILS ?? "")
    .split(",")
    .map((email) => email.trim().toLowerCase())
    .filter(Boolean);
  const email = String(res.locals.user?.email ?? "").trim().toLowerCase();

  if (!configured.length || !email || !configured.includes(email)) {
    return res.status(403).json({
      status: "error",
      message: "Administrator access is not enabled for this account",
    });
  }

  next();
}
