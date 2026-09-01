import { LRMSSessionState } from "../upstream/lrms.client.js";

import { SessionRepository } from "./session.repository.js";

export class MemorySessionRepository implements SessionRepository {
  private readonly sessions = new Map<string, LRMSSessionState>();

  async create(token: string, session: LRMSSessionState): Promise<void> {
    this.sessions.set(token, session);
  }

  async get(token: string): Promise<LRMSSessionState | null> {
    return this.sessions.get(token) ?? null;
  }

  async delete(token: string): Promise<void> {
    this.sessions.delete(token);
  }
}
