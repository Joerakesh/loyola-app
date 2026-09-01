import { LRMS_CONFIG } from "../config/lrms.js";
import { LRMSClient } from "../upstream/lrms.client.js";
import { transformDashboard } from "../transformers/dashboard.transformer.js";

export class DashboardService {
  constructor(private readonly lrms: LRMSClient) {}

  async getDashboard() {
    const response = await this.lrms.post(LRMS_CONFIG.endpoints.dashboard);

    return transformDashboard(response.data);
  }
}
