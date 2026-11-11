/**
 * Small in-memory TTL cache with a size cap and in-flight de-duplication.
 *
 * On Vercel each warm function instance keeps its own copy, which is exactly
 * what we want for short-lived response caching: it is free, fast, and a miss
 * just means one extra upstream call.
 */
interface Entry<V> {
  value: V;
  expiresAt: number;
}

export class TtlCache<V> {
  private readonly entries = new Map<string, Entry<V>>();
  private readonly inflight = new Map<string, Promise<V>>();

  constructor(private readonly maxEntries = 1000) {}

  get(key: string): V | undefined {
    const entry = this.entries.get(key);
    if (!entry) return undefined;

    if (entry.expiresAt <= Date.now()) {
      this.entries.delete(key);
      return undefined;
    }

    // Re-insert so the Map keeps recently used keys at the end (LRU order).
    this.entries.delete(key);
    this.entries.set(key, entry);
    return entry.value;
  }

  set(key: string, value: V, ttlMs: number): void {
    this.entries.delete(key);
    this.entries.set(key, { value, expiresAt: Date.now() + ttlMs });

    while (this.entries.size > this.maxEntries) {
      const oldest = this.entries.keys().next().value;
      if (oldest === undefined) break;
      this.entries.delete(oldest);
    }
  }

  delete(key: string): void {
    this.entries.delete(key);
  }

  /** Remove every key that starts with the prefix, e.g. all data of one user. */
  deletePrefix(prefix: string): void {
    for (const key of [...this.entries.keys()]) {
      if (key.startsWith(prefix)) this.entries.delete(key);
    }
  }

  get size(): number {
    return this.entries.size;
  }

  clear(): void {
    this.entries.clear();
    this.inflight.clear();
  }

  /**
   * Return the cached value, or run the loader once. Concurrent callers for the
   * same key share a single loader call. Failures are never cached.
   */
  async readThrough(
    key: string,
    ttlMs: number,
    loader: () => Promise<V>,
  ): Promise<V> {
    const hit = this.get(key);
    if (hit !== undefined) return hit;

    const pending = this.inflight.get(key);
    if (pending) return pending;

    const promise = loader()
      .then((value) => {
        this.set(key, value, ttlMs);
        return value;
      })
      .finally(() => {
        this.inflight.delete(key);
      });

    this.inflight.set(key, promise);
    return promise;
  }
}
