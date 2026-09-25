import { Collection, ObjectId } from "mongodb";

import { getDb } from "../config/mongo.js";
import { CALENDAR_CONFIG } from "../config/calendar.js";
import { CalendarMonthDocument } from "../models/calendar.model.js";

export class CalendarRepository {
  private async collection(): Promise<Collection<CalendarMonthDocument>> {
    const db = await getDb();

    return db.collection<CalendarMonthDocument>(
      CALENDAR_CONFIG.collectionName,
    );
  }

  /** Insert the month or replace its content (keeps the same `_id`). */
  async upsertMonth(
    month: Omit<CalendarMonthDocument, "_id" | "updatedAt">,
  ): Promise<void> {
    const existingId = await this.idByKey(month.key);

    if (existingId) {
      await (
        await this.collection()
      ).updateOne(
        { key: month.key },
        {
          $set: {
            year: month.year,
            month: month.month,
            days: month.days,
            sourceUrl: month.sourceUrl,
            fetchedAt: month.fetchedAt,
            updatedAt: new Date(),
          },
        },
      );
    } else {
      await (await this.collection()).insertOne({
        _id: new ObjectId(),
        ...month,
        updatedAt: new Date(),
      } as CalendarMonthDocument);
    }
  }

  async findByKeys(keys: string[]): Promise<CalendarMonthDocument[]> {
    if (keys.length === 0) {
      return [];
    }

    return (await this.collection())
      .find({ key: { $in: keys } })
      .toArray();
  }

  async ensureIndexes(): Promise<void> {
    const collection = await this.collection();

    await collection.createIndex({ key: 1 }, { unique: true });
    await collection.createIndex({ year: 1, month: 1 });
  }

  private async idByKey(key: string): Promise<ObjectId | null> {
    const doc = await (await this.collection()).findOne(
      { key },
      { projection: { _id: 1 } },
    );

    return doc?._id ?? null;
  }
}