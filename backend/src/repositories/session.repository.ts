import { LRMSSessionState } from "../upstream/lrms.client.js";

export interface SessionRepository {
  create(token: string, session: LRMSSessionState): Promise<void>;

  get(token: string): Promise<LRMSSessionState | null>;

  delete(token: string): Promise<void>;
}
