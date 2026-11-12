import { LRMS_CONFIG } from "../config/lrms.js";
import type { LRMSRequester } from "../upstream/lrms.client.js";
import {
  LRMSSubjectsResponse,
  transformSubjects,
} from "../transformers/subjects.transformer.js";
export class SubjectsService {
  constructor(private readonly lrms: LRMSRequester) {}

  async getSubjects() {
    const response = await this.lrms.post<LRMSSubjectsResponse>(
      LRMS_CONFIG.endpoints.subjects,
    );
    return transformSubjects(response.data);
  }
}
