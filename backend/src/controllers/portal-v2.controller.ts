import type { Request, Response } from "express";
import { PortalV2Service, type PortalSection } from "../services/portal-v2.service.js";
import { LRMS_CONFIG } from "../config/lrms.js";
import { credentialEncryptionService } from "../services/credential-encryption.service.js";
import { lrmsBridgeService } from "../services/lrms-bridge.service.js";
import { userRepository } from "../repositories/user.repository.js";
import { invalidateUserCache } from "../lib/erp-cache.js";
import { PlatformService } from "../services/platform.service.js";
import { getReflectionForDate } from "../content/reflections.js";
import type { LRMSRequester } from "../upstream/lrms.client.js";

const sections = new Set<PortalSection>([
  "profile", "dashboard", "attendance", "academics", "fees", "registrations",
]);
const platformCollections = new Set([
  "assignments", "announcements", "schedules", "reminders", "notifications",
]);

export class PortalV2Controller {
  async listPlatform(req: Request, res: Response) {
    res.setHeader("Cache-Control", "private, no-store");
    const collection = String(req.params.collection ?? "");
    if (!platformCollections.has(collection)) {
      return res.status(404).json({ status: "error", message: "Unknown platform collection" });
    }
    try {
      const user = res.locals.userDocument;
      const data = await new PlatformService({ collectionName: collection }).list(user._id, {
        limit: Math.min(100, Math.max(1, Number(req.query.limit) || 100)),
        read: req.query.unread === "true" ? false : undefined,
      });
      return res.json({ status: "success", data });
    } catch (error) {
      console.error("Portal v2 platform request failed:", error instanceof Error ? error.message : "Unknown error");
      return res.status(500).json({ status: "error", message: "Unable to load saved portal data" });
    }
  }

  async get(req: Request, res: Response) {
    res.setHeader("Cache-Control", "private, no-store");
    const section = String(req.params.section ?? "all");
    if (section !== "all" && !sections.has(section as PortalSection)) {
      return res.status(404).json({ status: "error", message: "Unknown portal section" });
    }

    try {
      const service = new PortalV2Service(res.locals.lrmsClient);
      const result = await service.get(section as PortalSection | "all");
      if (section === "dashboard" || section === "all") {
        const user = res.locals.userDocument;
        const collections = ["assignments", "announcements", "schedules", "reminders", "notifications"] as const;
        const platformResults = await Promise.all(collections.map(async (name) => {
          try {
            const data = await new PlatformService({ collectionName: name }).list(user._id, { limit: 50 });
            return { name, data };
          } catch (error) {
            return { name, data: null, error: error instanceof Error ? error.message : "Unable to load saved items" };
          }
        }));
        const dashboardData = (result.data.dashboard ?? { dashboard: null, attendance: null }) as Record<string, unknown>;
        for (const item of platformResults) dashboardData[item.name] = item.data;
        dashboardData.reflection = getReflectionForDate();
        result.data.dashboard = dashboardData;
        for (const item of platformResults) {
          if (item.error) result.unavailable.push({ section: item.name, message: item.error });
        }
      }
      const data = section === "all" ? result.data : result.data[section];
      return res.json({ status: "success", data: data ?? null, unavailable: result.unavailable });
    } catch (error) {
      console.error("Portal v2 request failed:", error instanceof Error ? error.message : "Unknown error");
      return res.status(502).json({ status: "error", message: "Unable to load portal data" });
    }
  }

  async syncPassword(req: Request, res: Response) {
    const user = res.locals.userDocument;
    const registrationNumber = user?.erpCredential?.registrationNumber;
    const { password } = req.body;
    if (!registrationNumber || typeof password !== "string" || !password.trim()) {
      return res.status(400).json({ status: "error", message: "A linked ERP account and password are required" });
    }
    try {
      await lrmsBridgeService.createClient(registrationNumber, password);
      await userRepository.bindErpCredentials(user._id, {
        registrationNumber,
        passwordCiphertext: credentialEncryptionService.encrypt(password),
        createdAt: new Date(),
      });
      await this.invalidate(user._id.toHexString());
      return res.json({ status: "success", message: "Saved ERP password verified and updated" });
    } catch (error) {
      console.error("Portal v2 password sync failed:", error instanceof Error ? error.message : "Unknown error");
      return res.status(400).json({ status: "error", message: "Could not verify that password with Loyola ERP" });
    }
  }

  async changePassword(req: Request, res: Response) {
    const user = res.locals.userDocument;
    const { currentPassword, newPassword } = req.body;
    if (!user?.erpCredential || typeof currentPassword !== "string" || !currentPassword || typeof newPassword !== "string" || !newPassword.trim()) {
      return res.status(400).json({ status: "error", message: "Current and new ERP passwords are required" });
    }
    try {
      const form = new URLSearchParams({ currentPassword, newPassword });
      const lrmsClient = res.locals.lrmsClient as LRMSRequester;
      const result = await lrmsClient.post<{ status?: string; message?: string }>(
        LRMS_CONFIG.endpoints.changePassword,
        form,
      );
      if (result.data.status !== "success") {
        return res.status(400).json({ status: "error", message: result.data.message ?? "Loyola ERP rejected the password change" });
      }

      await userRepository.bindErpCredentials(user._id, {
        registrationNumber: user.erpCredential.registrationNumber,
        passwordCiphertext: credentialEncryptionService.encrypt(newPassword),
        createdAt: new Date(),
      });
      await this.invalidate(user._id.toHexString());
      return res.json({ status: "success", message: result.data.message ?? "ERP password changed" });
    } catch (error) {
      console.error("Portal v2 password change failed:", error instanceof Error ? error.message : "Unknown error");
      return res.status(400).json({ status: "error", message: "Loyola ERP could not change the password. Check the current password and try again." });
    }
  }

  private async invalidate(userId: string) {
    await lrmsBridgeService.invalidate(userId);
    invalidateUserCache(userId);
  }
}

export const portalV2Controller = new PortalV2Controller();
