import { LRMS_CONFIG } from "../config/lrms.js";
import { LRMSClient } from "../upstream/lrms.client.js";
import { transformStudentProfile } from "../transformers/student.transformer.js";

export class StudentService {
  constructor(private readonly lrms: LRMSClient) {}

  async getProfile() {
    const response = await this.lrms.get(LRMS_CONFIG.endpoints.profile);

    return transformStudentProfile(response.data);
  }
}
