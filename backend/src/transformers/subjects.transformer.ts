interface LRMSSubject {
  course_desc: string;
  course_code: string;
  semester: number;
  credit: number;
  facultyname: string;
}

interface LRMSSubjectsResponse {
  data: LRMSSubject[];
  success: boolean;
}

export function transformSubjects(response: LRMSSubjectsResponse) {
  return response.data.map((subject) => ({
    course_code: subject.course_code,
    course_title: subject.course_desc.trim(),
    semester: subject.semester,
    credits: subject.credit,
    faculty: subject.facultyname.trim(),
  }));
}
