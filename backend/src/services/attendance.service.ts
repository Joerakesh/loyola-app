import { LRMS_CONFIG } from "../config/lrms.js";
import { LRMSClient } from "../upstream/lrms.client.js";
import { transformHourlyAttendance } from "../transformers/attendance.transformer.js";

export class AttendanceService {
  constructor(private readonly lrms: LRMSClient) {}

  async getSummary() {
    const response = await this.lrms.post(
      LRMS_CONFIG.endpoints.attendanceSummary,
    );

    return response.data;
  }

  async getHourly() {
    const response = await this.lrms.post(
      LRMS_CONFIG.endpoints.attendanceHourly,
    );

    return transformHourlyAttendance(response.data);
  }
}
