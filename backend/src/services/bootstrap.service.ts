import { LRMSClient } from "../upstream/lrms.client.js";
import { DashboardService } from "./dashboard.service.js";
import { AttendanceService } from "./attendance.service.js";
import { websiteService } from "./website.service.js";

export interface AttendanceSummary {
  present: number;
  absent: number;
  attendancePercentage: number;
}

export interface BootstrapPayload {
  student: {
    name: string;
    mobile: string;
    email: string;
  };
  fees: {
    totalPaid: number;
  };
  attendance: {
    summary: AttendanceSummary;
    last6Days: Array<{
      date: string;
      dayOrder: number | null;
      week: number | null;
      hours: Array<{
        hour: number;
        status: "present" | "absent" | "not_scheduled";
      }>;
    }>;
  };
  announcements: Array<{
    id: string;
    title: string;
    url: string;
    attachment: {
      url: string;
      filename: string;
      type: "pdf" | "image" | "file";
    } | null;
  }>;
  syncedAt: string;
}

/**
 * LRMS's attendance summary endpoint already computes present/absent/percent
 * server-side; it may nest them under `data` or return them flat — accept both.
 */
function normalizeSummary(raw: unknown): AttendanceSummary {
  const source = (raw as { data?: Record<string, unknown> } | null)?.data ??
    raw ?? {};

  return {
    present: Number((source as Record<string, unknown>).present ?? 0),
    absent: Number((source as Record<string, unknown>).absent ?? 0),
    attendancePercentage: Number(
      (source as Record<string, unknown>).attendancePercentage ?? 0,
    ),
  };
}

/**
 * Assembles everything the home screen needs in ONE round trip:
 * student profile + fees, attendance summary, the 6 most recent class days,
 * and the current college announcements (already cached server-side).
 */
export class BootstrapService {
  constructor(private readonly lrms: LRMSClient) {}

  async getPayload(): Promise<BootstrapPayload> {
    // The three ERP calls run in parallel on a single authenticated session —
    // no per-request login cost now that sessions are cached.
    const [dashboard, summaryRaw, hourly] = await Promise.all([
      new DashboardService(this.lrms).getDashboard(),
      new AttendanceService(this.lrms).getSummary(),
      new AttendanceService(this.lrms).getHourly(),
    ]);

    const last6Days = hourly
      .filter((day) =>
        day.hours.some(
          (hour) =>
            hour.status === "present" || hour.status === "absent",
        ),
      )
      .sort((a, b) => a.date.localeCompare(b.date))
      .slice(-6);

    let announcements: BootstrapPayload["announcements"] = [];

    try {
      announcements = await websiteService.getAnnouncements();
    } catch (error) {
      // The college site being down shouldn't sink the whole home screen.
      console.error("Bootstrap announcements error:", error);
    }

    return {
      student: dashboard.student,
      fees: dashboard.fees,
      attendance: {
        summary: normalizeSummary(summaryRaw),
        last6Days,
      },
      announcements,
      syncedAt: new Date().toISOString(),
    };
  }
}