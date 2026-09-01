export type AttendanceStatus = "present" | "absent" | "not_scheduled";

interface LRMSHourlyAttendance {
  dayorderid: string;
  attendancedate: string;

  h1?: string;
  h2?: string;
  h3?: string;
  h4?: string;
  h5?: string;
  h6?: string;
}

function transformStatus(value: string | undefined): AttendanceStatus {
  switch (value) {
    case "P":
      return "present";

    case "A":
      return "absent";

    default:
      return "not_scheduled";
  }
}

function parseAttendanceDate(value: string) {
  const [date, dayOrderInfo] = value.trim().split(/\s+/);

  const dayOrderMatch = dayOrderInfo?.match(/^(\d+)\((\d+)\)$/);

  return {
    date,
    dayOrder: dayOrderMatch ? Number(dayOrderMatch[1]) : null,
    week: dayOrderMatch ? Number(dayOrderMatch[2]) : null,
  };
}

export function transformHourlyAttendance(records: LRMSHourlyAttendance[]) {
  return records.map((record) => {
    const parsed = parseAttendanceDate(record.attendancedate);

    const hours = [1, 2, 3, 4, 5, 6].map((hour) => ({
      hour,
      status: transformStatus(
        record[`h${hour}` as keyof LRMSHourlyAttendance] as string | undefined,
      ),
    }));

    return {
      date: parsed.date,
      dayOrder: parsed.dayOrder,
      week: parsed.week,
      hours,
    };
  });
}
