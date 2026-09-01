interface LRMSDashboardData {
  twelth?: string;
  studentmobile?: string;
  studentemail?: string;
  totalpaid?: string;
  studentname?: string;
}

export interface LRMSDashboardResponse {
  data: LRMSDashboardData;
  status: string;
}

export function transformDashboard(response: LRMSDashboardResponse) {
  const dashboard = response.data;

  return {
    student: {
      name: dashboard.studentname?.trim() ?? "",
      mobile: dashboard.studentmobile ?? "",
      email: dashboard.studentemail ?? "",
    },

    fees: {
      totalPaid: Number(dashboard.totalpaid ?? 0),
    },

    documents: {
      twelfthCertificate: dashboard.twelth ?? null,
    },
  };
}
