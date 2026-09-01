import { LRMS_CONFIG } from "../config/lrms.js";
import { LRMSClient } from "../upstream/lrms.client.js";
import { transformInternalMarks } from "../transformers/marks.transformer.js";

export class MarksService {
  constructor(private readonly lrms: LRMSClient) {}

  async getInternalMarks(registerNumber: string) {
    const response = await this.lrms.get(
      `${LRMS_CONFIG.endpoints.internalMarks}?studentid=${encodeURIComponent(registerNumber)}`,
    );

    return transformInternalMarks(response.data);
  }
}
