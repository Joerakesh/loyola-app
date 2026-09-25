export interface Authentication {
  token: string;
  tokenType: string;
  expiresAt: number;
}

export interface User {
  id?: string;
  name?: string;
  email?: string;
  avatarUrl?: string;
  erpLinked?: boolean;
  linkedEmails?: string[];
}

export interface AuthResponse {
  status: string;
  authentication: Authentication;
  user?: User;
}

export interface DashboardResponse {
  status: string;
  data: DashboardData;
}

export interface DashboardData {
  student: {
    name: string;
    mobile: string;
    email: string;
    department?: string;
  };

  fees: {
    totalPaid: number;
  };

  documents: {
    twelfthCertificate: string | null;
  };
}

export interface AttendanceSummary {
  attendancePercentage: number;
  absent: number;
  present: number;
}

export interface AttendanceSummaryResponse {
  status: string;
  data: AttendanceSummary;
}

export interface AttendanceHour {
  hour: number;
  status: "present" | "absent" | "not_scheduled";
}

export interface AttendanceDay {
  date: string;
  dayOrder: number | null;
  week: number | null;
  hours: AttendanceHour[];
}

/** Single-call payload for the home screen (GET /api/v1/bootstrap). */
export interface BootstrapData {
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
    last6Days: AttendanceDay[];
  };
  announcements: WebsiteAnnouncement[];
  syncedAt: string;
}

export interface BootstrapResponse {
  status: string;
  data: BootstrapData;
}

export interface WebsiteAnnouncementAttachment {
  url: string;
  filename: string;
  type: "pdf" | "image" | "file";
}

export interface WebsiteAnnouncement {
  id: string;
  title: string;
  /** Absolute link the announcement points to. */
  url: string;
  /** Populated when the link is a downloadable file (e.g. a PDF circular). */
  attachment: WebsiteAnnouncementAttachment | null;
}

export interface AnnouncementsResponse {
  status: string;
  data: WebsiteAnnouncement[];
}

export interface CalendarEvent {
  /** ISO date, e.g. "2026-10-01". */
  date: string;
  /** Short weekday, e.g. "THU". */
  day: string;
  /** "Day-1" … "Day-6", or null when the day has no day order. */
  dayOrder: string | null;
  /** Event title(s), or null when the day only carries a day order. */
  event: string | null;
  /** "YYYY-MM" of the stored month. */
  monthKey: string;
}

export interface CalendarResponse {
  status: string;
  count: number;
  from: string;
  to: string;
  data: CalendarEvent[];
}
