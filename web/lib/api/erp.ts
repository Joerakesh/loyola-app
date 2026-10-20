import { apiFetch } from "./client";
import { getToken } from "../auth/session";
import type {
  AttendanceSummaryResponse,
  DashboardResponse,
} from "../../types/api";

function authHeaders(): HeadersInit {
  const token = getToken();
  if (!token) throw new Error("Not authenticated");
  return { Authorization: `Bearer ${token}` };
}

export async function getDashboard(): Promise<DashboardResponse> {
  return apiFetch<DashboardResponse>("/dashboard", { headers: authHeaders() });
}

export async function getAttendanceSummary(): Promise<AttendanceSummaryResponse> {
  return apiFetch<AttendanceSummaryResponse>("/attendance/summary", { headers: authHeaders() });
}

export async function getAttendanceHourly() {
  return apiFetch<{ status: string; data: Array<{ date: string; dayOrder: number; week: number; hours: Array<{ hour: number; status: "present" | "absent" | "not_scheduled" }> }> }>("/attendance/hourly", { headers: authHeaders() });
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
  return apiFetch<DataResponse<SubjectRecord[]>>("/subjects", { headers: authHeaders() });
}

export async function getInternalMarks() {
  return apiFetch<DataResponse<InternalMarkRecord[]>>("/marks/internal", { headers: authHeaders() });
}

export async function getStudentProfile() {
  return apiFetch<DataResponse<StudentProfile>>("/student/profile", { headers: authHeaders() });
}

export async function getSchedules() {
  return apiFetch<DataResponse<PlatformRecord[]>>("/schedules", { headers: authHeaders() });
}

export async function getAssignments() {
  return apiFetch<DataResponse<PlatformRecord[]>>("/assignments", { headers: authHeaders() });
}

export async function getAnnouncements() {
  return apiFetch<DataResponse<PlatformRecord[]>>("/announcements", { headers: authHeaders() });
}

export async function getReminders() {
  return apiFetch<DataResponse<PlatformRecord[]>>("/reminders", { headers: authHeaders() });
}

export async function getNotifications() {
  return apiFetch<DataResponse<PlatformRecord[]>>("/notifications", { headers: authHeaders() });
}
