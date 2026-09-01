interface LRMSStudentProfile {
  studentmobilenumber: string;
  academicyear: string;
  program_name: string;
  section: string;
  studentname: string;
  course_name: string;
  registerno: string;
  studentid: string;
}

interface LRMSStudentProfileResponse {
  data: LRMSStudentProfile;
  status: string;
}

export function transformStudentProfile(response: LRMSStudentProfileResponse) {
  const student = response.data;

  return {
    studentId: student.studentid,
    registerNumber: student.registerno,
    name: student.studentname.trim(),
    mobile: student.studentmobilenumber,
    academicYear: student.academicyear,
    program: student.program_name,
    course: student.course_name,
    section: student.section,
  };
}
