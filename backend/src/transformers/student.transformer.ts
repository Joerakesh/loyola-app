export interface LRMSStudentProfileResponse {
  data: Record<string, unknown>;
  status: string;
}

const PROFILE_FIELD_MAP: Record<string, string> = {
  studentmobilenumber: "mobile",
  academicyear: "academicYear",
  occupation: "occupation",
  distname: "district",
  program_name: "program",
  section: "section",
  annualincome: "annualIncome",
  is_detained: "isDetained",
  hostel_dayscholar: "hostelDayScholar",
  detained_details: "detainedDetails",
  mothername: "motherName",
  lang: "language",
  parentmobilenumber: "parentMobile",
  universityregisterno: "universityRegisterNumber",
  address: "address",
  course_name: "course",
  studentname: "name",
  parentemail: "parentEmail",
  sex: "sex",
  studentnameinlocal: "nameInLocalLanguage",
  created_timestamp: "createdAt",
  statename: "state",
  registerno: "registerNumber",
  religion: "religion",
  studentid: "studentId",
  fathername: "fatherName",
  studentemail: "email",
  nationality: "nationality",
  officeid: "officeId",
  dob: "dateOfBirth",
  tamil_name: "tamilName",
  category: "category",
};

export function transformStudentProfile(response: LRMSStudentProfileResponse) {
  const student = response.data ?? {};
  const profile: Record<string, unknown> = {};

  for (const [sourceKey, targetKey] of Object.entries(PROFILE_FIELD_MAP)) {
    profile[targetKey] = student[sourceKey] ?? null;
  }

  // Keep compatibility with existing mobile clients while exposing every
  // profile field returned by the LRMS endpoint.
  profile.name = typeof student.studentname === "string"
    ? student.studentname.trim()
    : "";
  return profile;
}
