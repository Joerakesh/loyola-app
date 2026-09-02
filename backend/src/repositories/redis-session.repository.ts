import { redis, connectRedis } from "../config/redis.js";
import { LRMSSessionState } from "../upstream/lrms.client.js";
import { SessionRepository } from "./session.repository.js";

export class RedisSessionRepository implements SessionRepository {
  private readonly prefix = "college-mobile:session:";

  private key(token: string) {
    return `${this.prefix}${token}`;
  }

  async create(token: string, session: LRMSSessionState): Promise<void> {
    await connectRedis();

    await redis.set(this.key(token), JSON.stringify(session), {
      EX: 60 * 60 * 24,
    });
  }

  async get(token: string): Promise<LRMSSessionState | null> {
    await connectRedis();

    const value = await redis.get(this.key(token));

    if (!value) {
      return null;
    }

    return JSON.parse(value) as LRMSSessionState;
  }

  async delete(token: string): Promise<void> {
    await connectRedis();

    await redis.del(this.key(token));
  }
}
