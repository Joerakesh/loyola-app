import {
  LRMSClient,
  SessionExpiredError,
  type LRMSRequester,
  type LRMSSessionState,
} from "../upstream/lrms.client.js";

/** What the manager needs to know about a user. */
export interface ErpUser {
  id: string;
  registrationNumber: string;
}

/** Optional second-level store so a cold serverless instance can reuse a
 * session another instance already created. */
export interface ErpSessionStore {
  load(userId: string): Promise<LRMSSessionState | null>;
  save(userId: string, session: LRMSSessionState, ttlMs: number): Promise<void>;
  remove(userId: string): Promise<void>;
}

export interface ErpSessionManagerOptions {
  /** Performs a full ERP login (login page, captcha, credentials). */
  login: (user: ErpUser) => Promise<LRMSClient>;
  store?: ErpSessionStore;
  /** Sliding idle lifetime of a cached session. */
  ttlMs?: number;
  maxEntries?: number;
  now?: () => number;
}

interface CachedSession {
  client: LRMSClient;
  expiresAt: number;
}

export const DEFAULT_SESSION_TTL_MS = 15 * 60 * 1000;

/**
 * Keeps one logged-in LRMS session per user.
 *
 *  - Requests reuse the cached session instead of logging in every time.
 *  - Parallel requests for the same user share a single login (single-flight).
 *  - When the ERP says the session has expired, the next caller refreshes it
 *    once and everyone else waiting reuses the refreshed session.
 */
export class ErpSessionManager {
  private readonly memory = new Map<string, CachedSession>();
  private readonly inflight = new Map<string, Promise<LRMSClient>>();
  private readonly ttlMs: number;
  private readonly maxEntries: number;
  private readonly now: () => number;

  constructor(private readonly options: ErpSessionManagerOptions) {
    this.ttlMs = options.ttlMs ?? DEFAULT_SESSION_TTL_MS;
    this.maxEntries = options.maxEntries ?? 500;
    this.now = options.now ?? Date.now;
  }

  /**
   * @param stale a client that just failed with SessionExpiredError. It is never
   * returned again; the caller gets a different (refreshed) one.
   */
  async acquire(user: ErpUser, stale?: LRMSClient): Promise<LRMSClient> {
    const cached = this.memory.get(user.id);

    if (cached && cached.expiresAt > this.now() && cached.client !== stale) {
      cached.expiresAt = this.now() + this.ttlMs; // sliding window
      return cached.client;
    }

    const pending = this.inflight.get(user.id);
    if (pending) return pending;

    const promise = this.open(user, stale).finally(() => {
      this.inflight.delete(user.id);
    });

    this.inflight.set(user.id, promise);
    return promise;
  }

  /** Forget a user's session, e.g. after they relink or unlink the ERP. */
  async invalidate(userId: string): Promise<void> {
    this.memory.delete(userId);
    this.inflight.delete(userId);

    try {
      await this.options.store?.remove(userId);
    } catch (error) {
      console.error("ERP session store remove failed:", describe(error));
    }
  }

  /** A client for one request that logs in lazily and heals expired sessions. */
  clientFor(user: ErpUser): LRMSRequester {
    return new ManagedLRMSClient(user, this);
  }

  private async open(user: ErpUser, stale?: LRMSClient): Promise<LRMSClient> {
    // A stale session came from the store or memory, so don't load it again.
    if (!stale && this.options.store) {
      try {
        const saved = await this.options.store.load(user.id);

        if (saved) {
          const client = LRMSClient.fromSession(saved);
          this.remember(user.id, client);
          return client;
        }
      } catch (error) {
        console.error("ERP session store load failed:", describe(error));
      }
    }

    const client = await this.options.login(user);
    this.remember(user.id, client);

    if (this.options.store) {
      try {
        const state = await client.exportSession(user.registrationNumber);
        await this.options.store.save(user.id, state, this.ttlMs);
      } catch (error) {
        console.error("ERP session store save failed:", describe(error));
      }
    }

    return client;
  }

  private remember(userId: string, client: LRMSClient) {
    this.memory.delete(userId);
    this.memory.set(userId, {
      client,
      expiresAt: this.now() + this.ttlMs,
    });

    while (this.memory.size > this.maxEntries) {
      const oldest = this.memory.keys().next().value;
      if (oldest === undefined) break;
      this.memory.delete(oldest);
    }
  }
}

class ManagedLRMSClient implements LRMSRequester {
  private current?: LRMSClient;

  constructor(
    private readonly user: ErpUser,
    private readonly manager: ErpSessionManager,
  ) {}

  get<T = unknown>(url: string) {
    return this.run((client) => client.get<T>(url));
  }

  post<T = unknown>(url: string, data?: unknown) {
    return this.run((client) => client.post<T>(url, data));
  }

  getHtml(url: string) {
    return this.run((client) => client.getHtml(url));
  }

  private async run<R>(operation: (client: LRMSClient) => Promise<R>): Promise<R> {
    const client = this.current ?? (await this.manager.acquire(this.user));
    this.current = client;

    try {
      return await operation(client);
    } catch (error) {
      if (!(error instanceof SessionExpiredError)) throw error;

      // Session expired upstream: refresh once (shared with parallel callers)
      // and retry. A second failure is a real error and is surfaced.
      const fresh = await this.manager.acquire(this.user, client);
      this.current = fresh;
      return operation(fresh);
    }
  }
}

function describe(error: unknown) {
  return error instanceof Error ? error.message : "unknown error";
}
