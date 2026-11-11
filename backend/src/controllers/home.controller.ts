import { Request, Response } from "express";

import { lrmsBridgeService } from "../services/lrms-bridge.service.js";
import { PlatformService } from "../services/platform.service.js";
import { DashboardService } from "../services/dashboard.service.js";
import { AttendanceService } from "../services/attendance.service.js";
import {
  ERP_TTL_MS,
  erpCacheKey,
  erpResponseCache,
  invalidateUserCache,
  type ApiBody,
} from "../lib/erp-cache.js";
import { getReflectionForDate } from "../content/reflections.js";

const PLATFORM_COLLECTIONS = [
  "assignments",
  "announcements",
  "schedules",
  "reminders",
  "notifications",
] as const;

const platformServices = Object.fromEntries(
  PLATFORM_COLLECTIONS.map((name) => [
    name,
    new PlatformService({ collectionName: name }),
  ]),
) as Record<(typeof PLATFORM_COLLECTIONS)[number], PlatformService>;

/**
 * One request that replaces the seven the dashboard used to make. Every section
 * loads in parallel and fails on its own, so one slow or failing source no
 * longer blanks the whole screen.
 */
export class HomeController {
  async get(req: Request, res: Response) {
    const userId: string = res.locals.user.id;
    const user = res.locals.userDocument;
    const refresh = req.query.refresh === "1";

    if (refresh) invalidateUserCache(userId);

    const erp = user?.erpCredential
      ? lrmsBridgeService.getClientForUser(user)
      : null;

    const cachedErp = async (
      resource: "dashboard" | "attendanceSummary",
      load: () => Promise<unknown>,
    ) => {
      const body = await erpResponseCache.readThrough(
        erpCacheKey(userId, resource),
        ERP_TTL_MS[resource],
        async (): Promise<ApiBody> => ({ status: "success", data: await load() }),
      );
      return body.data;
    };

    const platform = (name: (typeof PLATFORM_COLLECTIONS)[number]) =>
      platformServices[name].list(user._id, { limit: 50 });

    const sections = {
      dashboard: erp
        ? cachedErp("dashboard", () => new DashboardService(erp).getDashboard())
        : Promise.resolve(null),
      attendance: erp
        ? cachedErp("attendanceSummary", () =>
            new AttendanceService(erp).getSummary(),
          )
        : Promise.resolve(null),
      assignments: platform("assignments"),
      announcements: platform("announcements"),
      schedules: platform("schedules"),
      reminders: platform("reminders"),
      notifications: platform("notifications"),
    };

    const names = Object.keys(sections) as Array<keyof typeof sections>;
    const settled = await Promise.allSettled(Object.values(sections));

    const data: Record<string, unknown> = {};
    const failed: string[] = [];

    settled.forEach((result, index) => {
      const name = names[index];

      if (result.status === "fulfilled") {
        data[name] = result.value;
      } else {
        data[name] = null;
        failed.push(name);
        console.error(
          `Home section "${name}" failed:`,
          result.reason instanceof Error ? result.reason.message : result.reason,
        );
      }
    });

    // With the ERP linked, no academic data at all means the ERP is down.
    // Return an error so clients show a retry instead of an empty dashboard.
    if (erp && failed.includes("dashboard") && failed.includes("attendance")) {
      return res.status(502).json({
        status: "error",
        message: "Unable to reach the college ERP right now",
      });
    }

    res.setHeader("Cache-Control", "private, no-cache");

    return res.json({
      status: "success",
      data: { ...data, reflection: getReflectionForDate() },
      failed,
    });
  }
}

export const homeController = new HomeController();

