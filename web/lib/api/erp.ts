import { apiFetch } from "./client";
import { getToken } from "../auth/session";
import type {
  AttendanceSummary,
  AttendanceSummaryResponse,
  DashboardData,
  DashboardResponse,
} from "../../types/api";

function authHeaders(): HeadersInit {
  const token = getToken();
  if (!token) throw new Error("Not authenticated");
  return { Authorization: `Bearer ${token}` };
}

export type PortalSection = "profile" | "dashboard" | "attendance" | "academics" | "fees" | "registrations";
export interface PortalSectionResponse<T> {
  status: string;
  data: T | null;
  unavailable: Array<{ section: string; message: string }>;
}

export function getPortalSection<T>(section: PortalSection) {
  return apiFetch<PortalSectionResponse<T>>(`/v2/portal/${section}`, {
    headers: authHeaders(),
    cache: "no-store",
  });
}

export function syncPortalCredential(password: string) {
  return apiFetch<{status:string;message:string}>("/v2/portal/credentials", {
    method: "POST",
    headers: authHeaders(),
    body: JSON.stringify({ password }),
  });
}

export function changePortalPassword(currentPassword: string, newPassword: string) {
  return apiFetch<{status:string;message:string}>("/v2/portal/password", {
    method: "PUT",
    headers: authHeaders(),
    body: JSON.stringify({ currentPassword, newPassword }),
  });
}

export async function getDashboard(): Promise<DashboardResponse> {
  const response = await getPortalSection<{ dashboard: DashboardData | null }>("dashboard");
  if (!response.data?.dashboard) throw new Error("Dashboard data was not returned by the v2 API.");
  return { status: response.status, data: response.data.dashboard };
}

export async function getAttendanceSummary(): Promise<AttendanceSummaryResponse> {
  const response = await getPortalSection<{ summary: AttendanceSummary }>("attendance");
  if (!response.data?.summary) throw new Error("Attendance summary was not returned by the v2 API.");
  return { status: response.status, data: response.data.summary };
}

export async function getAttendanceHourly() {
  const response = await getPortalSection<{ hourly: Array<{ date: string; dayOrder: number; week: number; hours: Array<{ hour: number; status: "present" | "absent" | "not_scheduled" }> }> }>("attendance");
  if (!response.data?.hourly) throw new Error("Hourly attendance was not returned by the v2 API.");
  return { status: response.status, data: response.data.hourly };
}

export interface SubjectRecord {
  course_code: string;
  course_title: string;
  semester: number;
  credits: number;
  faculty: string;
}

export interface MarkComponent {
  id: string;
  name: string;
  mark: number | null;
  maxMark: number;
}

export interface InternalMarkRecord {
  courseCode: string;
  courseName: string;
  semester: number;
  credits: number;
  faculty: string;
  marksAvailable: boolean;
  components: MarkComponent[];
  totals: { outOf50: number; outOf100: number; attendance: number; final: number } | null;
}

export interface StudentProfile {
  studentId: string;
  registerNumber: string;
  name: string;
  mobile: string;
  academicYear: string;
  program: string;
  course: string;
  section: string;
}

export interface PlatformRecord {
  _id: string;
  title: string;
  body?: string;
  description?: string;
  subject?: string;
  location?: string;
  dayOfWeek?: string;
  startTime?: string;
  endTime?: string;
  date?: string;
  dueDate?: string;
  remindAt?: string;
  isDone?: boolean;
  isCompleted?: boolean;
  readAt?: string;
  pinned?: boolean;
  createdAt?: string;
  updatedAt?: string;
}

interface DataResponse<T> { status: string; data: T }

export async function getSubjects() {
  const response = await getPortalSection<{ subjects: SubjectRecord[] }>("academics");
  if (!response.data?.subjects) throw new Error("Subjects were not returned by the v2 API.");
  return { status: response.status, data: response.data.subjects };
}

export async function getInternalMarks() {
  const response = await getPortalSection<{ marks: InternalMarkRecord[] }>("academics");
  if (!response.data?.marks) throw new Error("Internal marks were not returned by the v2 API.");
  return { status: response.status, data: response.data.marks };
}

export async function getStudentProfile() {
  const response = await getPortalSection<{ profile: { data: Record<string, unknown> } }>("profile");
  const raw = response.data?.profile?.data;
  if (!raw) throw new Error("Student profile was not returned by the v2 API.");
  const get = (...names: string[]) => {
    const found = Object.entries(raw).find(([key]) => names.some((name) => key.toLowerCase() === name.toLowerCase()));
    return found?.[1] == null ? "" : String(found[1]);
  };
  return {
    status: response.status,
    data: {
      studentId: get("studentid"),
      registerNumber: get("registerno", "universityregisterno"),
      name: get("studentname"),
      mobile: get("studentmobilenumber"),
      academicYear: get("academicyear"),
      program: get("program_name"),
      course: get("course_name"),
      section: get("section"),
    } satisfies StudentProfile,
  };
}

export async function getSchedules() {
  return apiFetch<DataResponse<PlatformRecord[]>>("/v2/platform/schedules", { headers: authHeaders(), cache: "no-store" });
}

export async function getAssignments() {
  return apiFetch<DataResponse<PlatformRecord[]>>("/v2/platform/assignments", { headers: authHeaders(), cache: "no-store" });
}

export async function getAnnouncements() {
  return apiFetch<DataResponse<PlatformRecord[]>>("/v2/platform/announcements", { headers: authHeaders(), cache: "no-store" });
}

export async function getReminders() {
  return apiFetch<DataResponse<PlatformRecord[]>>("/v2/platform/reminders", { headers: authHeaders(), cache: "no-store" });
}

export async function getNotifications() {
  return apiFetch<DataResponse<PlatformRecord[]>>("/v2/platform/notifications", { headers: authHeaders(), cache: "no-store" });
}

export interface IgnatianValue { name: string; meaning: string }
export interface Reflection { theme: string; prompt: string; value: IgnatianValue }

/** Everything the dashboard shows, from one request. A section that failed on
 * the server is null and named in `failed`, so the rest of the page still works. */
export interface HomeData {
  dashboard: DashboardData | null;
  attendance: AttendanceSummary | null;
  assignments: PlatformRecord[] | null;
  announcements: PlatformRecord[] | null;
  schedules: PlatformRecord[] | null;
  reminders: PlatformRecord[] | null;
  notifications: PlatformRecord[] | null;
  reflection: Reflection;
}

export async function getHome(options: { refresh?: boolean } = {}) {
  type DashboardPortalData = {
    dashboard: DashboardData | null;
    attendance: AttendanceSummary | null;
    assignments: PlatformRecord[] | null;
    announcements: PlatformRecord[] | null;
    schedules: PlatformRecord[] | null;
    reminders: PlatformRecord[] | null;
    notifications: PlatformRecord[] | null;
    reflection: Reflection;
  };
  const response = await apiFetch<PortalSectionResponse<DashboardPortalData | null>>(
    options.refresh ? "/v2/portal/dashboard?refresh=1" : "/v2/portal/dashboard",
    { headers: authHeaders(), cache: "no-store" },
  );
  const bundle = response.data;
  return {
    status: response.status,
    data: {
      dashboard: bundle?.dashboard ?? null,
      attendance: bundle?.attendance ?? null,
      assignments: bundle?.assignments ?? null,
      announcements: bundle?.announcements ?? null,
      schedules: bundle?.schedules ?? null,
      reminders: bundle?.reminders ?? null,
      notifications: bundle?.notifications ?? null,
      reflection: bundle?.reflection,
    } as HomeData,
    failed: response.unavailable.map((item) => item.section),
  };
}
