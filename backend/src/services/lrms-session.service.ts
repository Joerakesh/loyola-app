import { LRMSClient, LRMSSessionState } from "../upstream/lrms.client.js";

import { SessionRepository } from "../repositories/session.repository.js";

import { MemorySessionRepository } from "../repositories/memory-session.repository.js";

class LRMSSessionService {
  constructor(private readonly repository: SessionRepository) {}

  async createSession(token: string, session: LRMSSessionState) {
    await this.repository.create(token, session);
  }

  async getSession(token: string): Promise<LRMSClient> {
    const session = await this.repository.get(token);

    if (!session) {
      throw new Error("Session not found or expired");
    }

    return LRMSClient.fromSession(session);
  }

  async deleteSession(token: string) {
    await this.repository.delete(token);
  }
}

export const lrmsSessionService = new LRMSSessionService(
  new MemorySessionRepository(),
);
