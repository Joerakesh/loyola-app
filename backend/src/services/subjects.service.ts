import { LRMS_CONFIG } from "../config/lrms.js";
import { LRMSClient } from "../upstream/lrms.client.js";
import { transformSubjects } from "../transformers/subjects.transformer.js";

export class SubjectsService {
  constructor(private readonly lrms: LRMSClient) {}

  async getSubjects() {
    const response = await this.lrms.post(LRMS_CONFIG.endpoints.subjects);

    return transformSubjects(response.data);
  }
}
