import { getDb } from "../config/mongo.js";
import { credentialEncryptionService } from "../services/credential-encryption.service.js";
import type { ErpSessionStore } from "../services/erp-session.manager.js";
import type { LRMSSessionState } from "../upstream/lrms.client.js";

interface ErpSessionDocument {
  _id: string; // user id
  registrationNumber: string;
  cookiesCiphertext: string;
  createdAt: number;
  expiresAt: Date;
}

/**
 * Persists ERP session cookies (encrypted with the same key as the stored ERP
 * credentials) with a TTL index, so Mongo removes them automatically.
 */
export class ErpSessionRepository implements ErpSessionStore {
  private async collection() {
    return (await getDb()).collection<ErpSessionDocument>("erp_sessions");
  }

  async load(userId: string): Promise<LRMSSessionState | null> {
    const doc = await (await this.collection()).findOne({ _id: userId });

    // The TTL monitor only runs about once a minute, so check expiry ourselves.
    if (!doc || doc.expiresAt.getTime() <= Date.now()) return null;

    return {
      cookies: credentialEncryptionService.decrypt(doc.cookiesCiphertext),
      registrationNumber: doc.registrationNumber,
      createdAt: doc.createdAt,
    };
  }

  async save(userId: string, session: LRMSSessionState, ttlMs: number) {
    await (await this.collection()).replaceOne(
      { _id: userId },
      {
        registrationNumber: session.registrationNumber,
        cookiesCiphertext: credentialEncryptionService.encrypt(session.cookies),
        createdAt: session.createdAt,
        expiresAt: new Date(Date.now() + ttlMs),
      },
      { upsert: true },
    );
  }

  async remove(userId: string) {
    await (await this.collection()).deleteOne({ _id: userId });
  }

  async ensureIndexes() {
    await (await this.collection()).createIndex(
      { expiresAt: 1 },
      { expireAfterSeconds: 0 },
    );
  }
}

export const erpSessionRepository = new ErpSessionRepository();
