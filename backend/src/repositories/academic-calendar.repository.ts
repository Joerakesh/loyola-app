import { createHash } from "node:crypto";
import type { Collection, Document } from "mongodb";
import { getDb } from "../config/mongo.js";
import type { AcademicCalendarMonth } from "./academic-calendar.service.js";

interface StoredMonth extends AcademicCalendarMonth {
  _id?: unknown;
  contentHash: string;
  version: number;
  archivedAt: Date;
}

function hashMonth(month: AcademicCalendarMonth): string {
  const stable = {
    year: month.year,
    monthNumber: month.monthNumber,
    month: month.month,
    entries: month.entries,
    sourceUrl: month.sourceUrl,
  };
  return createHash("sha256").update(JSON.stringify(stable)).digest("hex");
}

export class AcademicCalendarRepository {
  private async collections(): Promise<{
    latest: Collection<Document>;
    versions: Collection<Document>;
  }> {
    const db = await getDb();
    const latest = db.collection("academic_calendar_months");
    const versions = db.collection("academic_calendar_versions");
    await Promise.all([
      latest.createIndex({ year: 1, monthNumber: 1 }, { unique: true }),
      versions.createIndex({ year: 1, monthNumber: 1, version: 1 }, { unique: true }),
      versions.createIndex({ year: 1, monthNumber: 1, contentHash: 1 }, { unique: true }),
    ]);
    return { latest, versions };
  }

  async getMonth(year: number, monthNumber: number): Promise<AcademicCalendarMonth | null> {
    const { latest } = await this.collections();
    const doc = await latest.findOne({ year, monthNumber });
    if (!doc) return null;
    const stored = doc as unknown as StoredMonth;
    const { _id: _ignored, contentHash: _hash, version: _version, archivedAt: _archived, ...data } = stored;
    return data;
  }

  async archiveMonth(month: AcademicCalendarMonth): Promise<{
    changed: boolean;
    version: number;
    contentHash: string;
  }> {
    const { latest, versions } = await this.collections();
    const contentHash = hashMonth(month);
    const previousDoc = await latest.findOne({
      year: month.year,
      monthNumber: month.monthNumber,
    });
    const previous = previousDoc as unknown as StoredMonth | null;

    if (previous?.contentHash === contentHash) {
      // Refresh only fetch metadata; content and version remain untouched.
      await latest.updateOne(
        { year: month.year, monthNumber: month.monthNumber, contentHash },
        { $set: { fetchedAt: month.fetchedAt, sourceUrl: month.sourceUrl } },
      );
      return { changed: false, version: previous.version, contentHash };
    }

    const version = (previous?.version ?? 0) + 1;
    const archivedAt = new Date();
    const snapshot: StoredMonth = {
      ...month,
      contentHash,
      version,
      archivedAt,
    };

    await versions.insertOne(snapshot as unknown as Document);
    await latest.replaceOne(
      { year: month.year, monthNumber: month.monthNumber },
      snapshot as unknown as Document,
      { upsert: true },
    );

    return { changed: true, version, contentHash };
  }
}

export const academicCalendarRepository = new AcademicCalendarRepository();
