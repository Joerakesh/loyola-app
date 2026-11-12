import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { TtlCache } from "../src/lib/ttl-cache.js";

describe("TtlCache", () => {
  beforeEach(() => vi.useFakeTimers());
  afterEach(() => vi.useRealTimers());

  it("returns a value until it expires", () => {
    const cache = new TtlCache<string>();
    cache.set("a", "1", 1000);

    expect(cache.get("a")).toBe("1");
    vi.advanceTimersByTime(999);
    expect(cache.get("a")).toBe("1");
    vi.advanceTimersByTime(2);
    expect(cache.get("a")).toBeUndefined();
  });

  it("evicts the least recently used key beyond maxEntries", () => {
    const cache = new TtlCache<number>(2);
    cache.set("a", 1, 10_000);
    cache.set("b", 2, 10_000);
    cache.get("a"); // "a" is now more recent than "b"
    cache.set("c", 3, 10_000);

    expect(cache.get("b")).toBeUndefined();
    expect(cache.get("a")).toBe(1);
    expect(cache.get("c")).toBe(3);
  });

  it("deletes every key with a prefix", () => {
    const cache = new TtlCache<number>();
    cache.set("u1:a", 1, 10_000);
    cache.set("u1:b", 2, 10_000);
    cache.set("u2:a", 3, 10_000);

    cache.deletePrefix("u1:");

    expect(cache.get("u1:a")).toBeUndefined();
    expect(cache.get("u1:b")).toBeUndefined();
    expect(cache.get("u2:a")).toBe(3);
  });

  describe("readThrough", () => {
    it("runs the loader once for concurrent callers", async () => {
      const cache = new TtlCache<string>();
      const loader = vi.fn(async () => "value");

      const results = await Promise.all([
        cache.readThrough("k", 1000, loader),
        cache.readThrough("k", 1000, loader),
        cache.readThrough("k", 1000, loader),
      ]);

      expect(results).toEqual(["value", "value", "value"]);
      expect(loader).toHaveBeenCalledTimes(1);
    });

    it("serves later calls from cache, then reloads after expiry", async () => {
      const cache = new TtlCache<number>();
      let n = 0;
      const loader = async () => ++n;

      expect(await cache.readThrough("k", 1000, loader)).toBe(1);
      expect(await cache.readThrough("k", 1000, loader)).toBe(1);

      vi.advanceTimersByTime(1001);
      expect(await cache.readThrough("k", 1000, loader)).toBe(2);
    });

    it("does not cache failures", async () => {
      const cache = new TtlCache<string>();
      const loader = vi
        .fn<() => Promise<string>>()
        .mockRejectedValueOnce(new Error("boom"))
        .mockResolvedValueOnce("ok");

      await expect(cache.readThrough("k", 1000, loader)).rejects.toThrow("boom");
      await expect(cache.readThrough("k", 1000, loader)).resolves.toBe("ok");
      expect(loader).toHaveBeenCalledTimes(2);
    });
  });
});
