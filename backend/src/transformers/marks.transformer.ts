export interface LRMSMarkComponent {
  componentId: string;
  displayName: string;
  maxMark: number;
  mark: string;
}

export interface LRMSStudentMarks {
  course_desc: string;
  course_code: string;
  studentName: string;
  semester: number;

  interal_total_50: number;
  interal_total_100: number;

  attendance_Mark: number;
  Final_internal_total: number;

  marks: LRMSMarkComponent[];
}

export interface LRMSMarkCourse {
  course_desc: string;
  course_code: string;
  semester: number;
  credit: number;
  facultyname: string;

  marks: {
    students: LRMSStudentMarks[];
  };
}

export interface LRMSMarksResponse {
  data: LRMSMarkCourse[];
  success: boolean;
}

function parseMark(value: string): number | null {
  const trimmed = value.trim();

  if (!trimmed) {
    return null;
  }

  const parsed = Number(trimmed);

  return Number.isNaN(parsed) ? null : parsed;
}

export function transformInternalMarks(response: LRMSMarksResponse) {
  return response.data.map((course) => {
    const student = course.marks.students[0];

    if (!student) {
      return {
        courseCode: course.course_code,
        courseName: course.course_desc.trim(),
        semester: course.semester,
        credits: course.credit,
        faculty: course.facultyname.trim(),

        marksAvailable: false,

        components: [],

        totals: null,
      };
    }

    return {
      courseCode: course.course_code,
      courseName: course.course_desc.trim(),
      semester: course.semester,
      credits: course.credit,
      faculty: course.facultyname.trim(),

      marksAvailable: true,

      components: student.marks.map((component) => ({
        id: component.componentId,
        name: component.displayName,
        mark: parseMark(component.mark),
        maxMark: component.maxMark,
      })),

      totals: {
        outOf50: student.interal_total_50,
        outOf100: student.interal_total_100,
        attendance: student.attendance_Mark,
        final: student.Final_internal_total,
      },
    };
  });
}
