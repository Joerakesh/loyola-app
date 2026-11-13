import { Collection, ObjectId } from "mongodb";

import { getDb } from "../config/mongo.js";
import {
  ErpCredential,
  NewUser,
  PublicUser,
  UserDocument,
} from "../models/user.model.js";

export class UserRepository {
  private async collection(): Promise<Collection<UserDocument>> {
    const db = await getDb();
    return db.collection<UserDocument>("users");
  }

  async create(input: NewUser): Promise<UserDocument> {
    const now = new Date();
    const user: UserDocument = {
      _id: new ObjectId(),
      ...input,
      createdAt: now,
      updatedAt: now,
    };
    await (await this.collection()).insertOne(user);
    return user;
  }

  async findByGoogleId(googleId: string): Promise<UserDocument | null> {
    return (await this.collection()).findOne({ googleId });
  }

  async findByErpRegistrationNumber(registrationNumber: string): Promise<UserDocument | null> {
    return (await this.collection()).findOne({
      "erpCredential.registrationNumber": registrationNumber,
    });
  }

  async findByEmail(email: string): Promise<UserDocument | null> {
    return (await this.collection()).findOne({ email });
  }

  async findById(id: string): Promise<UserDocument | null> {
    let objectId: ObjectId;
    try { objectId = new ObjectId(id); } catch { return null; }
    return (await this.collection()).findOne({ _id: objectId });
  }

  async linkGoogleId(id: ObjectId, googleId: string): Promise<void> {
    await (await this.collection()).updateOne(
      { _id: id },
      { $set: { googleId, updatedAt: new Date() } },
    );
  }

  async updateAvatar(id: ObjectId, avatarUrl: string): Promise<void> {
    await (await this.collection()).updateOne(
      { _id: id },
      { $set: { avatarUrl, updatedAt: new Date() } },
    );
  }

  async bindErpCredentials(id: ObjectId, erpCredential: ErpCredential): Promise<void> {
    await (await this.collection()).updateOne(
      { _id: id },
      { $set: { erpCredential, updatedAt: new Date() } },
    );
  }

  async clearErpCredentials(id: ObjectId): Promise<void> {
    await (await this.collection()).updateOne(
      { _id: id },
      { $unset: { erpCredential: "" }, $set: { updatedAt: new Date() } },
    );
  }

  async bindEmail(id: ObjectId, email: string): Promise<void> {
    await (await this.collection()).updateOne(
      { _id: id },
      { $addToSet: { linkedEmails: email }, $set: { updatedAt: new Date() } },
    );
  }

  toPublicUser(user: UserDocument): PublicUser {
    return {
      id: user._id.toHexString(),
      ...(user.googleId ? { googleId: user.googleId } : {}),
      ...(user.email ? { email: user.email } : {}),
      name: user.name,
      avatarUrl: user.avatarUrl,
      linkedEmails: user.linkedEmails ?? [],
      erpLinked: !!user.erpCredential,
    };
  }

  async ensureIndexes(): Promise<void> {
    const collection = await this.collection();
    // Replace legacy non-sparse unique indexes: ERP-only accounts intentionally
    // have no Google ID or email, so those optional fields must be partial indexes.
    const existing = await collection.indexes();
    for (const name of ["googleId_1", "email_1"]) {
      const index = existing.find((item) => item.name === name);
      if (index && !index.partialFilterExpression) {
        await collection.dropIndex(name);
      }
    }
    await collection.createIndex(
      { googleId: 1 },
      { unique: true, partialFilterExpression: { googleId: { $type: "string" } } },
    );
    await collection.createIndex(
      { email: 1 },
      { unique: true, partialFilterExpression: { email: { $type: "string" } } },
    );
    await collection.createIndex(
      { "erpCredential.registrationNumber": 1 },
      { unique: true, sparse: true },
    );
  }
}

export const userRepository = new UserRepository();
