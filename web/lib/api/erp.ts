import { apiFetch } from "./client";
import { getToken } from "../auth/session";
import type {
  AttendanceSummaryResponse,
  BootstrapResponse,
  DashboardResponse,
} from "../../types/api";

function authHeaders(): HeadersInit {
  const token = getToken();

  if (!token) {
    throw new Error("Not authenticated");
  }

  return {
    Authorization: `Bearer ${token}`,
  };
}

export async function getDashboard(): Promise<DashboardResponse> {
  return apiFetch<DashboardResponse>("/dashboard", {
    headers: authHeaders(),
  });
}

export async function getAttendanceSummary(): Promise<AttendanceSummaryResponse> {
  return apiFetch<AttendanceSummaryResponse>("/attendance/summary", {
    headers: authHeaders(),
  });
}

export async function getAttendanceHourly() {
  return apiFetch("/attendance/hourly", {
    headers: authHeaders(),
  });
}

/**
 * One call that returns everything the home screen needs: student profile +
 * fees, attendance summary, the 6 most recent class days, and the current
 * college announcements.
 */
export async function getBootstrap(): Promise<BootstrapResponse> {
  return apiFetch<BootstrapResponse>("/bootstrap", {
    headers: authHeaders(),
  });
}
