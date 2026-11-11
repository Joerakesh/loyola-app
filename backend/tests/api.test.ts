import express from "express";
import request from "supertest";
import { beforeEach, describe, expect, it, vi } from "vitest";

// The real bootstrap talks to MongoDB; tests must never need a database.
vi.mock("../src/config/bootstrap.js", () => ({
  ensureIndexesOnce: () => Promise.resolve(),
}));

import app from "../src/server.js";
import { responseCache } from "../src/middleware/response-cache.middleware.js";
import { erpResponseCache } from "../src/lib/erp-cache.js";

describe("public API surface", () => {
  it("reports health", async () => {
    const res = await request(app).get("/api/health");

    expect(res.status).toBe(200);
    expect(res.body.status).toBe("ok");
  });

  it.each([
    "/api/v1/home",
    "/api/v1/dashboard",
    "/api/v1/attendance/summary",
    "/api/v1/subjects",
    "/api/v1/student/profile",
    "/api/v1/marks/internal",
    "/api/v1/reflections/today",
    "/api/v1/assignments",
  ])("requires authentication for %s", async (path) => {
    const res = await request(app).get(path);

    expect(res.status).toBe(401);
    expect(res.body.status).toBe("error");
  });

  it("sets security headers", async () => {
    const res = await request(app).get("/api/health");

    expect(res.headers["x-content-type-options"]).toBe("nosniff");
  });
});

describe("responseCache middleware", () => {
  let calls = 0;

  function makeApp(handler?: express.RequestHandler) {
    const server = express();

    server.use((_req, res, next) => {
      res.locals.user = { id: "user-1" };
      next();
    });
    server.get(
      "/data",
      responseCache("subjects"),
      handler ??
        ((_req, res) => {
          calls += 1;
          res.json({ status: "success", data: { calls } });
        }),
    );

    return server;
  }

  beforeEach(() => {
    calls = 0;
    erpResponseCache.clear();
  });

  it("serves the second request from cache without running the handler", async () => {
    const server = makeApp();

    const first = await request(server).get("/data");
    const second = await request(server).get("/data");

    expect(first.headers["x-cache"]).toBe("MISS");
    expect(second.headers["x-cache"]).toBe("HIT");
    expect(second.body).toEqual(first.body);
    expect(calls).toBe(1);
  });

  it("bypasses the cache with ?refresh=1 and stores the new value", async () => {
    const server = makeApp();

    await request(server).get("/data");
    const refreshed = await request(server).get("/data?refresh=1");
    const after = await request(server).get("/data");

    expect(refreshed.headers["x-cache"]).toBe("BYPASS");
    expect(refreshed.body.data.calls).toBe(2);
    expect(after.headers["x-cache"]).toBe("HIT");
    expect(after.body.data.calls).toBe(2);
  });

  it("never caches error responses", async () => {
    let attempts = 0;
    const server = makeApp((_req, res) => {
      attempts += 1;
      res.status(502).json({ status: "error", message: "ERP down" });
    });

    await request(server).get("/data");
    const second = await request(server).get("/data");

    expect(second.headers["x-cache"]).toBe("MISS");
    expect(second.headers["cache-control"]).toBe("no-store");
    expect(attempts).toBe(2);
  });

  it("keeps each user's data separate", async () => {
    const server = express();
    let current = "user-1";
    server.use((_req, res, next) => {
      res.locals.user = { id: current };
      next();
    });
    server.get("/data", responseCache("subjects"), (_req, res) => {
      res.json({ status: "success", data: { owner: current } });
    });

    const a = await request(server).get("/data");
    current = "user-2";
    const b = await request(server).get("/data");

    expect(a.body.data.owner).toBe("user-1");
    expect(b.body.data.owner).toBe("user-2");
  });
});
