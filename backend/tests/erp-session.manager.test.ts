import { describe, expect, it, vi } from "vitest";
import {
  ErpSessionManager,
  type ErpSessionStore,
  type ErpUser,
} from "../src/services/erp-session.manager.js";
import { LRMSClient, SessionExpiredError } from "../src/upstream/lrms.client.js";

const user: ErpUser = { id: "user-1", registrationNumber: "22UCS001" };

interface FakeClient {
  id: number;
  get: ReturnType<typeof vi.fn>;
  post: ReturnType<typeof vi.fn>;
  exportSession: ReturnType<typeof vi.fn>;
}

function makeLogin() {
  let counter = 0;
  const clients: FakeClient[] = [];

  const login = vi.fn(async () => {
    // Yield so parallel callers genuinely overlap.
    await Promise.resolve();
    const client: FakeClient = {
      id: ++counter,
      get: vi.fn(async () => ({ data: { ok: true } })),
      post: vi.fn(async () => ({ data: { ok: true } })),
      exportSession: vi.fn(async (registrationNumber: string) => ({
        cookies: `JSESSIONID=abc${counter}`,
        registrationNumber,
        createdAt: 0,
      })),
    };
    clients.push(client);
    return client as unknown as LRMSClient;
  });

  return { login, clients };
}

describe("ErpSessionManager", () => {
  it("logs in once and reuses the session for later requests", async () => {
    const { login } = makeLogin();
    const manager = new ErpSessionManager({ login });

    const a = await manager.acquire(user);
    const b = await manager.acquire(user);

    expect(a).toBe(b);
    expect(login).toHaveBeenCalledTimes(1);
  });

  it("shares one login between parallel requests (single-flight)", async () => {
    const { login } = makeLogin();
    const manager = new ErpSessionManager({ login });

    // This is the dashboard case: many requests at once, one ERP login.
    const sessions = await Promise.all(
      Array.from({ length: 7 }, () => manager.acquire(user)),
    );

    expect(new Set(sessions).size).toBe(1);
    expect(login).toHaveBeenCalledTimes(1);
  });

  it("keeps separate sessions per user", async () => {
    const { login } = makeLogin();
    const manager = new ErpSessionManager({ login });

    const a = await manager.acquire(user);
    const b = await manager.acquire({ ...user, id: "user-2" });

    expect(a).not.toBe(b);
    expect(login).toHaveBeenCalledTimes(2);
  });

  it("logs in again after the idle lifetime passes, but not before", async () => {
    const { login } = makeLogin();
    let now = 1_000;
    const manager = new ErpSessionManager({ login, ttlMs: 60_000, now: () => now });

    await manager.acquire(user);
    now += 59_000;
    await manager.acquire(user); // still fresh, and the window slides forward
    expect(login).toHaveBeenCalledTimes(1);

    now += 59_000; // within 60s of the last use, so still fresh
    await manager.acquire(user);
    expect(login).toHaveBeenCalledTimes(1);

    now += 61_000;
    await manager.acquire(user);
    expect(login).toHaveBeenCalledTimes(2);
  });

  it("never hands back the stale client it was told about", async () => {
    const { login } = makeLogin();
    const manager = new ErpSessionManager({ login });

    const first = await manager.acquire(user);
    const second = await manager.acquire(user, first);

    expect(second).not.toBe(first);
    expect(login).toHaveBeenCalledTimes(2);
  });

  it("refreshes only once when parallel requests all hit an expired session", async () => {
    const { login } = makeLogin();
    const manager = new ErpSessionManager({ login });

    const stale = await manager.acquire(user);
    const refreshed = await Promise.all([
      manager.acquire(user, stale),
      manager.acquire(user, stale),
      manager.acquire(user, stale),
    ]);

    expect(new Set(refreshed).size).toBe(1);
    expect(login).toHaveBeenCalledTimes(2); // initial + a single refresh
  });

  it("forgets the session on invalidate", async () => {
    const { login } = makeLogin();
    const manager = new ErpSessionManager({ login });

    await manager.acquire(user);
    await manager.invalidate(user.id);
    await manager.acquire(user);

    expect(login).toHaveBeenCalledTimes(2);
  });

  it("does not cache a failed login", async () => {
    const login = vi
      .fn<() => Promise<LRMSClient>>()
      .mockRejectedValueOnce(new Error("ERP down"))
      .mockResolvedValueOnce({} as LRMSClient);
    const manager = new ErpSessionManager({ login });

    await expect(manager.acquire(user)).rejects.toThrow("ERP down");
    await expect(manager.acquire(user)).resolves.toBeDefined();
    expect(login).toHaveBeenCalledTimes(2);
  });

  describe("with a persistent store", () => {
    function makeStore(initial: Parameters<ErpSessionStore["save"]>[1] | null = null) {
      const store = {
        load: vi.fn(async () => initial),
        save: vi.fn(async () => undefined),
        remove: vi.fn(async () => undefined),
      } satisfies ErpSessionStore;
      return store;
    }

    it("reuses a session saved by another instance instead of logging in", async () => {
      const { login } = makeLogin();
      const store = makeStore({
        cookies: "JSESSIONID=shared",
        registrationNumber: user.registrationNumber,
        createdAt: 0,
      });
      const manager = new ErpSessionManager({ login, store });

      const client = await manager.acquire(user);

      expect(client).toBeInstanceOf(LRMSClient);
      expect(login).not.toHaveBeenCalled();
    });

    it("saves a fresh login and skips the store when refreshing a stale session", async () => {
      const { login } = makeLogin();
      const store = makeStore();
      const manager = new ErpSessionManager({ login, store });

      const first = await manager.acquire(user);
      expect(store.save).toHaveBeenCalledTimes(1);

      store.load.mockClear();
      await manager.acquire(user, first);
      expect(store.load).not.toHaveBeenCalled();
      expect(login).toHaveBeenCalledTimes(2);
    });

    it("falls back to a normal login when the store is unavailable", async () => {
      const { login } = makeLogin();
      const store = makeStore();
      store.load.mockRejectedValue(new Error("mongo down"));
      store.save.mockRejectedValue(new Error("mongo down"));
      const manager = new ErpSessionManager({ login, store });
      vi.spyOn(console, "error").mockImplementation(() => undefined);

      await expect(manager.acquire(user)).resolves.toBeDefined();
      expect(login).toHaveBeenCalledTimes(1);
    });

    it("removes the stored session on invalidate", async () => {
      const { login } = makeLogin();
      const store = makeStore();
      const manager = new ErpSessionManager({ login, store });

      await manager.invalidate(user.id);

      expect(store.remove).toHaveBeenCalledWith(user.id);
      expect(login).not.toHaveBeenCalled();
    });
  });
});

describe("clientFor (self-healing client)", () => {
  it("makes no ERP call until the first request", async () => {
    const { login } = makeLogin();
    const manager = new ErpSessionManager({ login });

    manager.clientFor(user);

    expect(login).not.toHaveBeenCalled();
  });

  it("retries once with a fresh session when the ERP session has expired", async () => {
    const { login, clients } = makeLogin();
    const manager = new ErpSessionManager({ login });
    const client = manager.clientFor(user);

    await client.get("/warm-up"); // creates session #1
    clients[0].get.mockRejectedValueOnce(new SessionExpiredError("login page"));

    const result = await client.get<{ ok: boolean }>("/data");

    expect(result.data).toEqual({ ok: true });
    expect(login).toHaveBeenCalledTimes(2);
    expect(clients[1].get).toHaveBeenCalledWith("/data");
  });

  it("does not retry errors that are not an expired session", async () => {
    const { login, clients } = makeLogin();
    const manager = new ErpSessionManager({ login });
    const client = manager.clientFor(user);

    await client.post("/warm-up");
    clients[0].post.mockRejectedValueOnce(new Error("HTTP 500"));

    await expect(client.post("/data")).rejects.toThrow("HTTP 500");
    expect(login).toHaveBeenCalledTimes(1);
  });

  it("gives up after one retry so a broken ERP cannot loop forever", async () => {
    const { login, clients } = makeLogin();
    const manager = new ErpSessionManager({ login });
    const client = manager.clientFor(user);

    await client.get("/warm-up");
    clients[0].get.mockRejectedValue(new SessionExpiredError("expired"));
    login.mockImplementationOnce(async () => {
      const failing = {
        get: vi.fn().mockRejectedValue(new SessionExpiredError("expired again")),
        post: vi.fn(),
        exportSession: vi.fn(),
      };
      return failing as unknown as LRMSClient;
    });

    await expect(client.get("/data")).rejects.toThrow("expired again");
    expect(login).toHaveBeenCalledTimes(2);
  });
});
