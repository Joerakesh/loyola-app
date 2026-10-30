import { LRMS_CONFIG } from "../config/lrms.js";
import { LRMSClient } from "../upstream/lrms.client.js";
import { transformHourlyAttendance } from "../transformers/attendance.transformer.js";

interface LRMSHourlyAttendance {
  dayorderid: string;
  attendancedate: string;
  h1?: string;
  h2?: string;
  h3?: string;
  h4?: string;
  h5?: string;
  h6?: string;
}

interface LRMSAttendanceSummary {
  attendancePercentage?: string | number;
  absent?: string | number;
  present?: string | number;
  [key: string]: unknown;
}

function toFiniteNumber(value: unknown): number {
  const parsed = typeof value === "number" ? value : Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
}

export class AttendanceService {
  constructor(private readonly lrms: LRMSClient) {}

  async getSummary() {
    // The captured ERP response sends attendancePercentage as a string while
    // the app contract expects numbers. Normalize all displayed totals.
    const response = await this.lrms.post<LRMSAttendanceSummary>(
      LRMS_CONFIG.endpoints.attendanceSummary,
    );

    return {
      ...response.data,
      attendancePercentage: toFiniteNumber(
        response.data.attendancePercentage,
      ),
      absent: toFiniteNumber(response.data.absent),
      present: toFiniteNumber(response.data.present),
    };
  }

  async getHourly() {
    const response = await this.lrms.post<LRMSHourlyAttendance[]>(
      LRMS_CONFIG.endpoints.attendanceHourly,
    );

    return transformHourlyAttendance(response.data);
  }
}
