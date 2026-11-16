import { createHash } from "node:crypto";
import type { Collection, Document } from "mongodb";
import { getDb } from "../config/mongo.js";
import type {
  CollegeAnnouncement,
  CollegeEvent,
} from "../services/college-site.service.js";

export interface CollegeUpdatesSnapshot {
  announcements: CollegeAnnouncement[];
  events: CollegeEvent[];
  sources: { homepage: string; calendar: string };
  fetchedAt: string;
}

interface StoredSnapshot extends CollegeUpdatesSnapshot {
  contentHash: string;
  version: number;
  archivedAt: Date;
}

interface ScrapeLock {
  _id: string;
  nextAllowedAt: Date;
  lastStartedAt?: Date;
}

function contentHash(snapshot: CollegeUpdatesSnapshot): string {
  // Sort copies by stable ID so harmless source ordering changes do not
  // create a new archive version.
  const stable = {
    announcements: [...snapshot.announcements].sort((a, b) => a.id.localeCompare(b.id)),
    events: [...snapshot.events].sort((a, b) => a.id.localeCompare(b.id)),
  };
  return createHash("sha256").update(JSON.stringify(stable)).digest("hex");
}

function publicSnapshot(doc: StoredSnapshot): CollegeUpdatesSnapshot & { announcementVersion: number } {
  const {
    contentHash: _hash,
    version: _version,
    archivedAt: _archivedAt,
    ...snapshot
  } = doc;
  return { ...snapshot, announcementVersion: doc.version };
}

export class CollegeUpdatesRepository {
  private async collections(): Promise<{
    latest: Collection<Document>;
    versions: Collection<Document>;
  }> {
    const db = await getDb();
    const latest = db.collection("college_updates_latest");
    const versions = db.collection("college_updates_versions");
    await Promise.all([
      latest.createIndex({ key: 1 }, { unique: true }),
      versions.createIndex({ key: 1, version: 1 }, { unique: true }),
      versions.createIndex({ key: 1, contentHash: 1 }, { unique: true }),
    ]);
    return { latest, versions };
  }

  async acquireScrapeSlot(cooldownMs = 5 * 60_000): Promise<boolean> {
    const db = await getDb();
    // This collection uses a string _id, unlike MongoDB's default ObjectId.
    const locks: Collection<ScrapeLock> = db.collection<ScrapeLock>(
      "college_updates_scrape_locks",
    );
    const now = new Date();
    await locks.updateOne(
      { _id: "loyola-homepage" },
      { $setOnInsert: { nextAllowedAt: new Date(0) } },
      { upsert: true },
    );
    const result = await locks.updateOne(
      { _id: "loyola-homepage", nextAllowedAt: { $lte: now } },
      { $set: { nextAllowedAt: new Date(now.getTime() + cooldownMs), lastStartedAt: now } },
    );
    return result.modifiedCount === 1;
  }

  async getLatest(): Promise<(CollegeUpdatesSnapshot & { announcementVersion: number }) | null> {
    const { latest } = await this.collections();
    const doc = await latest.findOne({ key: "loyola-homepage" });
    return doc ? publicSnapshot(doc as unknown as StoredSnapshot) : null;
  }

  async archive(snapshot: CollegeUpdatesSnapshot): Promise<{
    changed: boolean;
    version: number;
    announcements: number;
    events: number;
  }> {
    const { latest, versions } = await this.collections();
    const key = "loyola-homepage";
    const hash = contentHash(snapshot);
    const previousDoc = await latest.findOne({ key });
    const previous = previousDoc as unknown as (StoredSnapshot & { key: string }) | null;

    if (previous?.contentHash === hash) {
      await latest.updateOne(
        { key, contentHash: hash },
        { $set: { fetchedAt: snapshot.fetchedAt, sources: snapshot.sources } },
      );
      return {
        changed: false,
        version: previous.version,
        announcements: snapshot.announcements.length,
        events: snapshot.events.length,
      };
    }

    const version = (previous?.version ?? 0) + 1;
    const stored: StoredSnapshot & { key: string } = {
      ...snapshot,
      key,
      contentHash: hash,
      version,
      archivedAt: new Date(),
    };

    // Write the immutable history record before replacing the latest pointer.
    await versions.insertOne(stored as unknown as Document);
    await latest.replaceOne({ key }, stored as unknown as Document, { upsert: true });

    return {
      changed: true,
      version,
      announcements: snapshot.announcements.length,
      events: snapshot.events.length,
    };
  }
}

export const collegeUpdatesRepository = new CollegeUpdatesRepository();
