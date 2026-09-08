import { ObjectId } from "mongodb";

import { PlatformRepository, ListOptions } from "../repositories/platform.repository.js";
import { PlatformDocument, PlatformInput } from "../models/platform.model.js";

export interface PlatformServiceConfig {
  collectionName: string;
}

function cleanInput(input: PlatformInput): Record<string, unknown> {
  return Object.fromEntries(
    Object.entries(input).filter(
      ([, value]) => value !== undefined && value !== null,
    ),
  );
}

export class PlatformService {
  private readonly repository: PlatformRepository;

  constructor(config: PlatformServiceConfig) {
    this.repository = new PlatformRepository(config.collectionName);
  }

  async list(userId: ObjectId, options: ListOptions = {}) {
    return this.repository.list(userId, options);
  }

  async create(userId: ObjectId, input: PlatformInput) {
    const now = new Date();

    const doc: PlatformDocument = {
      _id: new ObjectId(),
      userId,
      createdAt: now,
      updatedAt: now,
      ...cleanInput(input),
    } as PlatformDocument;

    await this.repository.create(doc);

    return doc;
  }

  async get(id: string, userId: ObjectId) {
    return this.repository.findById(this.parseId(id), userId);
  }

  async update(id: string, userId: ObjectId, patch: PlatformInput) {
    return this.repository.update(this.parseId(id), userId, cleanInput(patch));
  }

  async markRead(id: string, userId: ObjectId) {
    return this.repository.update(this.parseId(id), userId, {
      readAt: new Date(),
    } as Partial<PlatformDocument>);
  }

  async markDone(id: string, userId: ObjectId) {
    return this.repository.update(this.parseId(id), userId, {
      isDone: true,
      doneAt: new Date(),
    } as Partial<PlatformDocument>);
  }

  async remove(id: string, userId: ObjectId) {
    return this.repository.remove(this.parseId(id), userId);
  }

  async ensureIndexes() {
    await this.repository.ensureIndexes();
  }

  private parseId(id: string): ObjectId {
    try {
      return new ObjectId(id);
    } catch {
      throw new Error("Invalid id");
    }
  }
}