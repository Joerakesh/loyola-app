import { Request, Response, NextFunction } from "express";
import {
  ERP_TTL_MS,
  erpCacheKey,
  erpResponseCache,
  type ErpResource,
} from "../lib/erp-cache.js";

/**
 * Serves a user's ERP data from memory while it is fresh. Place it AFTER
 * requireAuth and BEFORE requireErpClient so a cache hit never touches the ERP.
 *
 * Clients can pass `?refresh=1` (pull-to-refresh) to skip the cache and update it.
 */
export function responseCache(resource: ErpResource) {
  const ttlMs = ERP_TTL_MS[resource];
  const maxAgeSeconds = Math.floor(ttlMs / 1000);

  return (req: Request, res: Response, next: NextFunction) => {
    const userId: string | undefined = res.locals.user?.id;
    if (!userId) return next();

    const key = erpCacheKey(userId, resource);
    const refresh = req.query.refresh === "1";

    res.setHeader("Vary", "Authorization");

    if (!refresh) {
      const hit = erpResponseCache.get(key);

      if (hit) {
        res.setHeader("X-Cache", "HIT");
        res.setHeader("Cache-Control", `private, max-age=${maxAgeSeconds}`);
        return res.json(hit);
      }
    }

    res.setHeader("X-Cache", refresh ? "BYPASS" : "MISS");

    const send = res.json.bind(res);

    res.json = (body: unknown) => {
      const ok =
        res.statusCode === 200 &&
        typeof body === "object" &&
        body !== null &&
        (body as { status?: unknown }).status === "success";

      if (ok) {
        erpResponseCache.set(key, body as never, ttlMs);
        res.setHeader("Cache-Control", `private, max-age=${maxAgeSeconds}`);
      } else {
        res.setHeader("Cache-Control", "no-store");
      }

      return send(body);
    };

    next();
  };
}
