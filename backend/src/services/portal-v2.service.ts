import { LRMS_CONFIG } from "../config/lrms.js";
import { AttendanceService } from "./attendance.service.js";
import { DashboardService } from "./dashboard.service.js";
import { MarksService } from "./marks.service.js";
import { StudentService } from "./student.service.js";
import { SubjectsService } from "./subjects.service.js";
import type { LRMSRequester } from "../upstream/lrms.client.js";

export type PortalSection =
  | "profile"
  | "dashboard"
  | "attendance"
  | "academics"
  | "fees"
  | "registrations";

type Loader = () => Promise<unknown>;

/** LRMS endpoints inconsistently wrap lists as { data: [...] } or expose them
 * directly. Normalize the common response envelope before sending it to v2. */
function responseRows(value: unknown): unknown[] {
  if (Array.isArray(value)) return value;
  if (!value || typeof value !== "object") return [];
  const data = Object.entries(value as Record<string, unknown>)
    .find(([key]) => key.toLowerCase() === "data")?.[1];
  if (Array.isArray(data)) return data;
  if (data && typeof data === "object") return responseRows(data);
  return [];
}

export class PortalV2Service {
  constructor(private readonly lrms: LRMSRequester) {}

  async get(section: PortalSection | "all") {
    const sections: Record<PortalSection, Loader> = {
      profile: () => this.profile(),
      dashboard: () => this.dashboard(),
      attendance: () => this.attendance(),
      academics: () => this.academics(),
      fees: () => this.fees(),
      registrations: () => this.registrations(),
    };

    const requested = section === "all" ? Object.keys(sections) as PortalSection[] : [section];
    const results = await Promise.all(
      requested.map(async (name) => [name, await this.settle(name, sections[name])] as const),
    );
    const data = Object.fromEntries(results.map(([name, result]) => [name, result.data]));
    const unavailable: Array<{ section: string; message: string }> = results
      .filter(([, result]) => result.error)
      .map(([name, result]) => ({ section: name, message: result.error ?? "LRMS request failed" }));

    return { data, unavailable };
  }

  private async profile() {
    const [profile, sidebar] = await Promise.all([
      this.lrms.get<Record<string, unknown>>(LRMS_CONFIG.endpoints.profile),
      this.lrms.get<Record<string, unknown>>(LRMS_CONFIG.endpoints.sidebar),
    ]);
    return { profile: profile.data, sidebar: sidebar.data };
  }

  private async dashboard() {
    const [dashboard, attendance] = await Promise.all([
      new DashboardService(this.lrms).getDashboard(),
      new AttendanceService(this.lrms).getSummary(),
    ]);
    return { dashboard, attendance };
  }

  private async attendance() {
    const [summary, hourly, profile] = await Promise.all([
      new AttendanceService(this.lrms).getSummary(),
      new AttendanceService(this.lrms).getHourly(),
      new StudentService(this.lrms).getProfile(),
    ]);
    const form = new URLSearchParams({ studentid: profile.studentId });
    const subjectWise = await this.lrms.post<unknown>(
      LRMS_CONFIG.endpoints.subjectAttendance,
      form,
    );
    return { summary, hourly, subjectWise: subjectWise.data };
  }

  private async academics() {
    const [subjects, profile] = await Promise.all([
      new SubjectsService(this.lrms).getSubjects(),
      new StudentService(this.lrms).getProfile(),
    ]);
    const marks = await new MarksService(this.lrms).getInternalMarks(profile.studentId);
    return { subjects, marks };
  }

  private async fees() {
    const profile = await new StudentService(this.lrms).getProfile();
    const form = new URLSearchParams({ registerno: profile.registerNumber });
    const [dashboard, payments, due, notification, activeChallans, registrationPayments,
      condonationPayments, department] = await Promise.all([
      new DashboardService(this.lrms).getDashboard().catch(() => null),
      this.lrms.get<unknown>(LRMS_CONFIG.endpoints.feePaid),
      this.lrms.get<unknown>(LRMS_CONFIG.endpoints.feeDue),
      this.lrms.post<unknown>(LRMS_CONFIG.endpoints.feeNotification),
      this.lrms.get<unknown>(LRMS_CONFIG.endpoints.activeChallans),
      this.lrms.post<unknown>(LRMS_CONFIG.endpoints.registrationNumberPayments, form),
      this.lrms.post<unknown>(LRMS_CONFIG.endpoints.condonationPayments, form),
      this.lrms.get<unknown>(LRMS_CONFIG.endpoints.department),
    ]);
    return {
      // The dashboard summary can still report paid fees when the detailed
      // receipt endpoint returns no rows for the current academic year.
      summaryTotalPaid: dashboard?.fees.totalPaid ?? null,
      payments: responseRows(payments.data),
      due: responseRows(due.data),
      notification: notification.data,
      activeChallans: activeChallans.data,
      registrationPayments: registrationPayments.data,
      condonationPayments: condonationPayments.data,
      department: department.data,
    };
  }

  private async registrations() {
    const [semester, course, assessment, hallTicket, club, studentClub] = await Promise.all([
      this.lrms.get<unknown>(LRMS_CONFIG.endpoints.semesterRegistration),
      this.lrms.get<unknown>(LRMS_CONFIG.endpoints.courseRegistration),
      this.lrms.get<unknown>(LRMS_CONFIG.endpoints.assessmentRegistration),
      this.lrms.get<unknown>(LRMS_CONFIG.endpoints.hallTicketRegistration),
      this.lrms.get<unknown>(LRMS_CONFIG.endpoints.clubRegistration),
      this.lrms.get<unknown>(LRMS_CONFIG.endpoints.studentClubRegistration),
    ]);
    return {
      semester: semester.data,
      course: course.data,
      assessment: assessment.data,
      hallTicket: hallTicket.data,
      club: club.data,
      studentClub: studentClub.data,
    };
  }

  private async settle(name: string, loader: Loader): Promise<{ data: unknown; error?: string }> {
    try {
      return { data: await loader() };
    } catch (error) {
      // Keep student records out of logs and return a safe section-level error.
      console.error(
        `[Portal v2] ${name} unavailable:`,
        error instanceof Error ? error.message : "LRMS request failed",
      );
      return {
        data: null,
        error: error instanceof Error ? error.message : "LRMS request failed",
      };
    }
  }
}
