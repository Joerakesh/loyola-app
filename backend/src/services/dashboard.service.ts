import { LRMS_CONFIG } from "../config/lrms.js";
import type { LRMSRequester } from "../upstream/lrms.client.js";
import {
  LRMSDashboardResponse,
  transformDashboard,
} from "../transformers/dashboard.transformer.js";
export class DashboardService {
  constructor(private readonly lrms: LRMSRequester) {}

  async getDashboard() {
    const response = await this.lrms.post<LRMSDashboardResponse>(
      LRMS_CONFIG.endpoints.dashboard,
    );

    return transformDashboard(response.data);
  }
}
