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
