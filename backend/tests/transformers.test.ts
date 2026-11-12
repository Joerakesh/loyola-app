import { describe, expect, it } from "vitest";
import { transformHourlyAttendance } from "../src/transformers/attendance.transformer.js";
import { transformInternalMarks } from "../src/transformers/marks.transformer.js";
import { transformSubjects } from "../src/transformers/subjects.transformer.js";
import { transformDashboard } from "../src/transformers/dashboard.transformer.js";

describe("transformHourlyAttendance", () => {
  it("maps P/A/other to present/absent/not_scheduled and parses day order", () => {
    const [day] = transformHourlyAttendance([
      { dayorderid: "1", attendancedate: "12-08-2026 3(2)", h1: "P", h2: "A", h3: "-" },
    ]);

    expect(day.date).toBe("12-08-2026");
    expect(day.dayOrder).toBe(3);
    expect(day.week).toBe(2);
    expect(day.hours).toHaveLength(6);
    expect(day.hours[0]).toEqual({ hour: 1, status: "present" });
    expect(day.hours[1]).toEqual({ hour: 2, status: "absent" });
    expect(day.hours[2]).toEqual({ hour: 3, status: "not_scheduled" });
    expect(day.hours[5]).toEqual({ hour: 6, status: "not_scheduled" });
  });

  it("returns null day order and week when the date has no day-order suffix", () => {
    const [day] = transformHourlyAttendance([
      { dayorderid: "1", attendancedate: "12-08-2026" },
    ]);

    expect(day.dayOrder).toBeNull();
    expect(day.week).toBeNull();
  });
});

describe("transformInternalMarks", () => {
  const course = {
    course_desc: "  Data Structures ",
    course_code: "CS201",
    semester: 3,
    credit: 4,
    facultyname: " Dr. A ",
  };

  it("renames components, parses marks and keeps blank marks as null", () => {
    const [result] = transformInternalMarks({
      success: true,
      data: [
        {
          ...course,
          marks: {
            students: [
              {
                course_desc: "",
                course_code: "CS201",
                studentName: "S",
                semester: 3,
                interal_total_50: 40,
                interal_total_100: 80,
                attendance_Mark: 5,
                Final_internal_total: 45,
                marks: [
                  { componentId: "1", displayName: "Comp 1", maxMark: 25, mark: "20" },
                  { componentId: "2", displayName: "Comp 3a", maxMark: 10, mark: " " },
                  { componentId: "3", displayName: "Quiz", maxMark: 5, mark: "abc" },
                ],
              },
            ],
          },
        },
      ],
    });

    expect(result.courseName).toBe("Data Structures");
    expect(result.faculty).toBe("Dr. A");
    expect(result.marksAvailable).toBe(true);
    expect(result.components.map((c) => c.name)).toEqual(["CIA 1", "Comp 1", "Quiz"]);
    expect(result.components.map((c) => c.mark)).toEqual([20, null, null]);
    expect(result.totals).toEqual({ outOf50: 40, outOf100: 80, attendance: 5, final: 45 });
  });

  it("marks a course as unavailable when no student record exists", () => {
    const [result] = transformInternalMarks({
      success: true,
      data: [{ ...course, marks: { students: [] } }],
    });

    expect(result.marksAvailable).toBe(false);
    expect(result.components).toEqual([]);
    expect(result.totals).toBeNull();
  });
});

describe("transformSubjects", () => {
  it("trims text and renames fields for the API contract", () => {
    expect(
      transformSubjects({
        success: true,
        data: [
          { course_desc: " Maths ", course_code: "MA101", semester: 1, credit: 3, facultyname: " Fr. B " },
        ],
      }),
    ).toEqual([
      { course_code: "MA101", course_title: "Maths", semester: 1, credits: 3, faculty: "Fr. B" },
    ]);
  });
});

describe("transformDashboard", () => {
  it("falls back to safe defaults for missing fields", () => {
    const result = transformDashboard({ status: "success", data: {} });

    expect(result.student).toEqual({ name: "", mobile: "", email: "" });
    expect(result.fees.totalPaid).toBe(0);
    expect(result.documents.twelfthCertificate).toBeNull();
  });

  it("converts the paid fees string to a number", () => {
    const result = transformDashboard({
      status: "success",
      data: { totalpaid: "45000", studentname: "  Joe  " },
    });

    expect(result.fees.totalPaid).toBe(45000);
    expect(result.student.name).toBe("Joe");
  });
});
