import { LRMSClient, LRMSSessionState } from "../upstream/lrms.client.js";
import { LRMS_CONFIG } from "../config/lrms.js";

interface SessionEntry {
  session: LRMSSessionState;
  expiresAt: number;
}

/**
 * In-memory cache of authenticated LRMS sessions, keyed by registration
 * number.
 *
 * Previously every ERP request performed a full login (GET / to grab the
 * login page + CAPTCHA, then POST /ajax/validateLogin.jsp) — see the old
 * `LRMSBridgeService.createClient`. With this cache one login per account
 * lasts `LRMS_CONFIG.sessionTtlSeconds`, and parallel requests for the same
 * account share a single in-flight login instead of racing each other (which
 * also risked LRMS invalidating the earlier session).
 *
 * Single-instance assumption: this lives in process memory. Fine for a single
 * deployed backend; if you scale to multiple instances, move it to Redis/Mongo.
 */
export class LRMSSessionCacheService {
  private readonly cache = new Map<string, SessionEntry>();
  private readonly inflight = new Map<string, Promise<LRMSClient>>();

  /** Session TTL in ms. */
  private readonly ttlMs = LRMS_CONFIG.sessionTtlSeconds * 1000;

  /**
   * Returns an authenticated LRMS client for the account, reusing a valid
   * cached session when one exists and logging in only on a miss/expiry.
   */
  async getClient(
    registrationNumber: string,
    password: string,
  ): Promise<LRMSClient> {
    const entry = this.cache.get(registrationNumber);

    if (entry && Date.now() < entry.expiresAt) {
      return LRMSClient.fromSession(entry.session);
    }

    // Multiple concurrent requests for the same account share one login.
    const pending = this.inflight.get(registrationNumber);

    if (pending) {
      return pending;
    }

    const task = this.login(registrationNumber, password);
    this.inflight.set(registrationNumber, task);

    // Drop the in-flight marker whether the login succeeds or fails so the
    // next caller retries cleanly.
    task.finally(() => {
      this.inflight.delete(registrationNumber);
    });

    return task;
  }

  /** Drops a stored session (e.g. after a known dead-session failure). */
  evict(registrationNumber: string): void {
    this.cache.delete(registrationNumber);
  }

  clear(): void {
    this.cache.clear();
  }

  private async login(
    registrationNumber: string,
    password: string,
  ): Promise<LRMSClient> {
    const client = new LRMSClient();

    const loginPage = await client.getLoginPage();

    const result = await client.login(
      registrationNumber,
      password,
      loginPage.captcha,
    );

    if (!result || result.status !== "success") {
      throw new Error(result?.message ?? "LRMS login failed");
    }

    const session = await client.exportSession(registrationNumber);

    this.cache.set(registrationNumber, {
      session,
      expiresAt: Date.now() + this.ttlMs,
    });

    return client;
  }
}

export const lrmsSessionCacheService = new LRMSSessionCacheService();