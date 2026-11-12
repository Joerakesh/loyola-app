export const LRMS_CONFIG = {
  baseUrl:
    process.env.LRMS_BASE_URL ?? "https://lrms.loyolacollege.edu/studenterp",

  endpoints: {
    login: "/ajax/validateLogin.jsp",
    changePassword: "/ajax/changepassword.jsp",

    dashboard: "/ajax/getStudentDashboard.jsp",
    sidebar: "/ajax/getSidebarStudentDetails.jsp",
    profile: "/ajax/getStudentProfile.jsp",
    subjectAttendance: "/ajax/getStudentAttendanceSubjectWise.jsp",
    department: "/ajax/getDepartmentName.jsp",

    subjects: "/ajax/getStudentSubjects.jsp",

    attendanceSummary: "/ajax/getAttendanceSummary.jsp",
    attendanceHourly: "/ajax/getHourWiseAttendance_new.jsp",

    internalMarks: "/ajax/getsubjectInternalMarks.jsp",

    semesterRegistration: "/ajax/checkSemRegistrationStatus.jsp",

    clubRegistration: "/ajax/checkClubRegistrationStatus.jsp",

    feePaid: "/ajax/getFeePaidDetails.jsp",
    feeDue: "/ajax/getFeeDueDetails.jsp",
    activeChallans: "/ajax/getActiveChallanConfigurations.jsp",
    feeNotification: "/ajax/checkFeeChallanNotification.jsp",
    registrationNumberPayments: "/ajax/getRegisterNoPaymentDetails.jsp",
    condonationPayments: "/ajax/getCondonationPaymentDetails.jsp",

    courseRegistration: "/ajax/checkCourseRegistration.jsp",
    assessmentRegistration: "/ajax/isStudentSubjectFacultyAssessmentOpen.jsp",
    hallTicketRegistration: "/ajax/checkSemHTStatus.jsp",
    studentClubRegistration: "/ajax/getStudentClubRegistrationStatus.jsp",

    examFee: "/ajax/getSemesterExamFeeStructure.jsp",
    examChallan: "/ajax/checkSemesterExamChallanStatus.jsp",
    examPayment: "/ajax/checkSemesterExamPaymentStatus.jsp",
  },
} as const;
