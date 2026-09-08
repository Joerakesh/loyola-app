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
      googleId: input.googleId,
      email: input.email,
      name: input.name,
      avatarUrl: input.avatarUrl,
      createdAt: now,
      updatedAt: now,
    };

    await (await this.collection()).insertOne(user);

    return user;
  }

  async findByGoogleId(googleId: string): Promise<UserDocument | null> {
    return (await this.collection()).findOne({ googleId });
  }

  async findByEmail(email: string): Promise<UserDocument | null> {
    return (await this.collection()).findOne({ email });
  }

  async findById(id: string): Promise<UserDocument | null> {
    let objectId: ObjectId;

    try {
      objectId = new ObjectId(id);
    } catch {
      return null;
    }

    return (await this.collection()).findOne({ _id: objectId });
  }

  async linkGoogleId(id: ObjectId, googleId: string): Promise<void> {
    await (await this.collection()).updateOne(
      { _id: id },
      { $set: { googleId, updatedAt: new Date() } },
    );
  }

  async bindErpCredentials(
    id: ObjectId,
    erpCredential: ErpCredential,
  ): Promise<void> {
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
      {
        $addToSet: { linkedEmails: email },
        $set: { updatedAt: new Date() },
      },
    );
  }

  toPublicUser(user: UserDocument): PublicUser {
    return {
      id: user._id.toHexString(),
      googleId: user.googleId,
      email: user.email,
      name: user.name,
      avatarUrl: user.avatarUrl,
      linkedEmails: user.linkedEmails ?? [],
      erpLinked: !!user.erpCredential,
    };
  }

  async ensureIndexes(): Promise<void> {
    await (await this.collection()).createIndex({ googleId: 1 }, { unique: true });
    await (await this.collection()).createIndex({ email: 1 }, { unique: true });
  }
}

export const userRepository = new UserRepository();