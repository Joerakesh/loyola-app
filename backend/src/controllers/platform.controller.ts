import { Request, Response } from "express";
import { ObjectId } from "mongodb";

import { PlatformService } from "../services/platform.service.js";
import { PlatformInput } from "../models/platform.model.js";

export interface PlatformControllerOptions {
  read?: boolean;
  done?: boolean;
}

export class PlatformController {
  private readonly service: PlatformService;

  constructor(
    collectionName: string,
    readonly options: PlatformControllerOptions = {},
  ) {
    this.service = new PlatformService({ collectionName });
  }

  async ensureIndexes() {
    await this.service.ensureIndexes();
  }

  async list(req: Request, res: Response) {
    try {
      const userId = this.userId(res);

      const unreadOnly = req.query.unread === "true";

      const docs = await this.service.list(userId, {
        limit: Number(req.query.limit) || 100,
        read: unreadOnly ? false : undefined,
      });

      return res.json({ status: "success", data: docs });
    } catch (error) {
      console.error("Platform list error:", error);

      return res.status(500).json({
        status: "error",
        message: "Unable to list items",
      });
    }
  }

  async create(req: Request, res: Response) {
    try {
      const userId = this.userId(res);

      const doc = await this.service.create(userId, req.body as PlatformInput);

      return res.status(201).json({ status: "success", data: doc });
    } catch (error) {
      console.error("Platform create error:", error);

      return res.status(400).json({
        status: "error",
        message: "Unable to create item",
      });
    }
  }

  async get(req: Request, res: Response) {
    try {
      const userId = this.userId(res);

      const doc = await this.service.get(this.paramId(req), userId);

      if (!doc) {
        return res.status(404).json({
          status: "error",
          message: "Item not found",
        });
      }

      return res.json({ status: "success", data: doc });
    } catch (error) {
      console.error("Platform get error:", error);

      return res.status(404).json({
        status: "error",
        message: "Item not found",
      });
    }
  }

  async update(req: Request, res: Response) {
    try {
      const userId = this.userId(res);

      const doc = await this.service.update(
        this.paramId(req),
        userId,
        req.body as PlatformInput,
      );

      if (!doc) {
        return res.status(404).json({
          status: "error",
          message: "Item not found",
        });
      }

      return res.json({ status: "success", data: doc });
    } catch (error) {
      console.error("Platform update error:", error);

      return res.status(400).json({
        status: "error",
        message: "Unable to update item",
      });
    }
  }

  async markRead(req: Request, res: Response) {
    try {
      const userId = this.userId(res);

      const doc = await this.service.markRead(this.paramId(req), userId);

      if (!doc) {
        return res.status(404).json({
          status: "error",
          message: "Item not found",
        });
      }

      return res.json({ status: "success", data: doc });
    } catch (error) {
      console.error("Platform mark-read error:", error);

      return res.status(400).json({
        status: "error",
        message: "Unable to update item",
      });
    }
  }

  async markDone(req: Request, res: Response) {
    try {
      const userId = this.userId(res);

      const doc = await this.service.markDone(this.paramId(req), userId);

      if (!doc) {
        return res.status(404).json({
          status: "error",
          message: "Item not found",
        });
      }

      return res.json({ status: "success", data: doc });
    } catch (error) {
      console.error("Platform mark-done error:", error);

      return res.status(400).json({
        status: "error",
        message: "Unable to update item",
      });
    }
  }

  async remove(req: Request, res: Response) {
    try {
      const userId = this.userId(res);

      const deleted = await this.service.remove(this.paramId(req), userId);

      if (!deleted) {
        return res.status(404).json({
          status: "error",
          message: "Item not found",
        });
      }

      return res.json({
        status: "success",
        message: "Item deleted",
      });
    } catch (error) {
      console.error("Platform delete error:", error);

      return res.status(400).json({
        status: "error",
        message: "Unable to delete item",
      });
    }
  }

  private userId(res: Response): ObjectId {
    const user = res.locals.userDocument;

    if (!user) {
      throw new Error("User not found");
    }

    return user._id;
  }

  private paramId(req: Request): string {
    return String(req.params.id);
  }
}