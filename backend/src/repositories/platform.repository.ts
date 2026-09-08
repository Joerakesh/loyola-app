import { Collection, ObjectId } from "mongodb";

import { getDb } from "../config/mongo.js";
import { PlatformDocument } from "../models/platform.model.js";

export type PlatformSort =
  | { createdAt: -1 | 1 }
  | { dueDate: -1 | 1 }
  | { remindAt: -1 | 1 }
  | { date: -1 | 1 };

export interface ListOptions {
  limit?: number;
  sort?: PlatformSort;
  read?: boolean;
}

export class PlatformRepository {
  constructor(private readonly collectionName: string) {}

  private async collection(): Promise<Collection<PlatformDocument>> {
    const db = await getDb();

    return db.collection<PlatformDocument>(this.collectionName);
  }

  async create(doc: PlatformDocument): Promise<void> {
    await (await this.collection()).insertOne(doc);
  }

  async list(
    userId: ObjectId,
    options: ListOptions = {},
  ): Promise<PlatformDocument[]> {
    const query: Record<string, unknown> = { userId };

    if (options.read === false) {
      query.readAt = { $exists: false };
    }

    return (await this.collection())
      .find(query)
      .sort(options.sort ?? { createdAt: -1 } as never)
      .limit(options.limit ?? 100)
      .toArray();
  }

  async findById(
    id: ObjectId,
    userId: ObjectId,
  ): Promise<PlatformDocument | null> {
    return (await this.collection()).findOne({ _id: id, userId });
  }

  async update(
    id: ObjectId,
    userId: ObjectId,
    patch: Partial<PlatformDocument>,
  ): Promise<PlatformDocument | null> {
    return (await this.collection()).findOneAndUpdate(
      { _id: id, userId },
      { $set: { ...patch, updatedAt: new Date() } },
      { returnDocument: "after" },
    );
  }

  async remove(id: ObjectId, userId: ObjectId): Promise<boolean> {
    const result = await (await this.collection()).deleteOne({
      _id: id,
      userId,
    });

    return result.deletedCount > 0;
  }

  async ensureIndexes(): Promise<void> {
    await (await this.collection()).createIndex({ userId: 1, createdAt: -1 });
  }
}