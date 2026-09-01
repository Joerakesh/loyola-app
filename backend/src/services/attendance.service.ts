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
export class AttendanceService {
  constructor(private readonly lrms: LRMSClient) {}

  async getSummary() {
    const response = await this.lrms.post(
      LRMS_CONFIG.endpoints.attendanceSummary,
    );

    return response.data;
  }

  async getHourly() {
    const response = await this.lrms.post<LRMSHourlyAttendance[]>(
      LRMS_CONFIG.endpoints.attendanceHourly,
    );

    return transformHourlyAttendance(response.data);
  }
}
