"use client";

import { useEffect, useMemo, useState } from "react";
import {
  Activity,
  AlertCircle,
  CalendarDays,
  CheckCircle2,
  ChevronDown,
  ChevronUp,
  Clock,
  Clock3,
  TrendingUp,
  XCircle,
} from "lucide-react";

import AppShell from "@/components/layout/app-shell"; // Adjust path if needed
import { getAttendanceHourly } from "@/lib/api/erp";

type AttendanceStatus = "present" | "absent" | "not_scheduled";

type AttendanceHour = {
  hour: number;
  status: AttendanceStatus;
};

type AttendanceDay = {
  date: string;
  dayOrder: number;
  week: number;
  hours: AttendanceHour[];
};

type AttendanceResponse = {
  status: string;
  data: AttendanceDay[];
};

export default function AttendancePage() {
  const [days, setDays] = useState<AttendanceDay[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    async function loadAttendance() {
      try {
        setLoading(true);
        setError("");

        const response = (await getAttendanceHourly()) as AttendanceResponse;

        if (response.status !== "success") {
          throw new Error("Unable to load attendance");
        }

        setDays(response.data ?? []);
      } catch (error) {
        console.error(error);

        setError(
          error instanceof Error
            ? error.message
            : "Unable to load attendance.",
        );
      } finally {
        setLoading(false);
      }
    }

    loadAttendance();
  }, []);

  const stats = useMemo(() => {
    let present = 0;
    let absent = 0;

    for (const day of days) {
      for (const hour of day.hours) {
        if (hour.status === "present") {
          present++;
        }

        if (hour.status === "absent") {
          absent++;
        }
      }
    }

    const total = present + absent;
    const percentage = total === 0 ? 0 : (present / total) * 100;

    return {
      present,
      absent,
      total,
      percentage,
    };
  }, [days]);

  if (loading) {
    return (
      <AppShell>
        <div className="flex min-h-[60vh] items-center justify-center">
          <div className="flex items-center gap-3 text-slate-500">
            <div className="h-5 w-5 animate-spin rounded-full border-2 border-slate-300 border-t-[#8b0000]" />
            Loading attendance details...
          </div>
        </div>
      </AppShell>
    );
  }

  if (error) {
    return (
      <AppShell>
        <div className="rounded-2xl border border-red-200 bg-red-50 p-6 text-red-700">
          <h2 className="font-semibold">Unable to load attendance</h2>
          <p className="mt-1 text-sm">{error}</p>
        </div>
      </AppShell>
    );
  }

  return (
    <AppShell>
      <div className="mx-auto max-w-7xl space-y-8">
        {/* Header */}
        <section>
          <div className="flex flex-col justify-between gap-4 md:flex-row md:items-end">
            <div>
              <p className="text-sm font-medium text-[#8b0000]">
                Academic overview
              </p>

              <h1 className="mt-1 text-3xl font-bold tracking-tight md:text-4xl">
                Attendance Log
              </h1>

              <p className="mt-2 text-slate-500">
                Keep track of your daily attendance and class participation.
              </p>
            </div>

            <div className="flex items-center gap-2 text-sm text-slate-500">
              <CalendarDays size={17} />
              Attendance Dashboard
            </div>
          </div>
        </section>

        {/* Overview Section */}
        <section className="grid gap-6 lg:grid-cols-3">
          {/* Main Percentage Card */}
          <div className="rounded-3xl bg-[#8b0000] p-7 text-white shadow-lg lg:col-span-1">
            <div className="flex items-start justify-between">
              <div>
                <div className="flex items-center gap-2 text-sm text-white/70">
                  <TrendingUp size={17} />
                  Overall attendance
                </div>

                <div className="mt-4 text-5xl font-bold">
                  {stats.percentage.toFixed(1)}%
                </div>

                <p className="mt-2 text-sm text-white/70">
                  {stats.percentage >= 75
                    ? "You are above the required minimum."
                    : "Your attendance is below 75%."}
                </p>
              </div>

              <div className="rounded-2xl bg-white/10 p-3">
                <Activity size={25} />
              </div>
            </div>

            {/* Progress Bar */}
            <div className="mt-8">
              <div className="h-3 overflow-hidden rounded-full bg-white/20">
                <div
                  className="h-full rounded-full bg-white transition-all"
                  style={{
                    width: `${Math.min(stats.percentage, 100)}%`,
                  }}
                />
              </div>
            </div>

            <div className="mt-4 flex justify-between text-xs text-white/70">
              <span>0%</span>
              <span>75% minimum</span>
              <span>100%</span>
            </div>
          </div>

          {/* Stats Grid */}
          <div className="grid grid-cols-2 gap-4 lg:col-span-2">
            <StatCard
              title="Present"
              value={stats.present.toString()}
              description="Total classes attended"
              icon={<CheckCircle2 size={20} />}
            />

            <StatCard
              title="Absent"
              value={stats.absent.toString()}
              description="Total classes missed"
              icon={<XCircle size={20} />}
            />

            <StatCard
              title="Attendance Days"
              value={days.length.toString()}
              description="Days recorded"
              icon={<CalendarDays size={20} />}
            />

            <StatCard
              title="Total Classes"
              value={stats.total.toString()}
              description="Scheduled sessions"
              icon={<Clock size={20} />}
            />
          </div>
        </section>

        {/* Attendance History */}
        <section>
          <div className="mb-4">
            <h2 className="text-xl font-bold">Attendance history</h2>
            <p className="text-sm text-slate-500">
              Daily attendance records and hourly breakdowns.
            </p>
          </div>

          <AttendanceHistoryTable days={days} />
        </section>
      </div>
    </AppShell>
  );
}

// ----------------------------------------------------------------------
// Reusable Components
// ----------------------------------------------------------------------

function StatCard({
  title,
  value,
  description,
  icon,
}: {
  title: string;
  value: string;
  description: string;
  icon: React.ReactNode;
}) {
  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm transition hover:border-slate-300 hover:shadow-md">
      <div className="flex items-center justify-between">
        <div className="text-sm font-medium text-slate-500">{title}</div>
        <div className="rounded-xl bg-slate-100 p-2.5 text-slate-600">
          {icon}
        </div>
      </div>
      <div className="mt-4 text-3xl font-bold">{value}</div>
      <div className="mt-1 text-xs text-slate-500">{description}</div>
    </div>
  );
}

function AttendanceHistoryTable({ days }: { days: AttendanceDay[] }) {
  const [expandedDate, setExpandedDate] = useState<string | null>(null);

  const sortedDays = [...days].sort(
    (a, b) => parseDate(b.date).getTime() - parseDate(a.date).getTime(),
  );

  if (sortedDays.length === 0) {
    return (
      <div className="rounded-2xl border border-slate-200 bg-white p-8 text-center shadow-sm">
        <p className="text-sm text-slate-500">No attendance records found.</p>
      </div>
    );
  }

  return (
    <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
      <div className="overflow-x-auto">
        <table className="w-full text-left text-sm">
          <thead className="border-b border-slate-100 bg-slate-50/50">
            <tr>
              <th className="px-6 py-4 text-xs font-semibold uppercase tracking-wider text-slate-500">
                Date
              </th>
              <th className="px-6 py-4 text-xs font-semibold uppercase tracking-wider text-slate-500">
                Schedule Info
              </th>
              <th className="px-6 py-4 text-xs font-semibold uppercase tracking-wider text-slate-500">
                Classes Present
              </th>
              <th className="px-6 py-4 text-xs font-semibold uppercase tracking-wider text-slate-500">
                Daily Score
              </th>
              <th className="px-6 py-4 text-right">
                {/* Empty header for the toggle chevron column */}
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {sortedDays.map((day) => (
              <AttendanceTableRow
                key={`${day.date}-${day.week}`}
                day={day}
                expanded={expandedDate === day.date}
                onToggle={() =>
                  setExpandedDate(expandedDate === day.date ? null : day.date)
                }
              />
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function AttendanceTableRow({
  day,
  expanded,
  onToggle,
}: {
  day: AttendanceDay;
  expanded: boolean;
  onToggle: () => void;
}) {
  const present = day.hours.filter((hour) => hour.status === "present").length;
  const absent = day.hours.filter((hour) => hour.status === "absent").length;
  const scheduled = present + absent;
  const percentage = scheduled === 0 ? 0 : (present / scheduled) * 100;
  const hasAttendance = scheduled > 0;

  return (
    <>
      <tr
        onClick={onToggle}
        className="cursor-pointer transition-colors hover:bg-slate-50"
      >
        <td className="whitespace-nowrap px-6 py-4">
          <span className="font-semibold text-slate-900">
            {formatDate(day.date)}
          </span>
        </td>

        <td className="whitespace-nowrap px-6 py-4">
          <div className="flex items-center gap-2 text-xs text-slate-500">
            <span className="rounded bg-slate-100 px-2 py-0.5 font-medium">
              Week {day.week}
            </span>
            <span className="rounded bg-slate-100 px-2 py-0.5 font-medium">
              Day Order {day.dayOrder}
            </span>
          </div>
        </td>

        <td className="whitespace-nowrap px-6 py-4">
          {hasAttendance ? (
            <div className="flex items-baseline gap-1">
              <span className="text-sm font-bold text-slate-900">{present}</span>
              <span className="text-sm text-slate-400">/ {scheduled}</span>
            </div>
          ) : (
            <span className="text-sm text-slate-400">No classes</span>
          )}
        </td>

        <td className="whitespace-nowrap px-6 py-4">
          <span
            className={`inline-flex items-center justify-center rounded-full px-3 py-1 text-xs font-bold ${!hasAttendance
                ? "bg-slate-100 text-slate-500"
                : percentage >= 75
                  ? "bg-emerald-100 text-emerald-700"
                  : "bg-red-100 text-red-700"
              }`}
          >
            {hasAttendance ? `${percentage.toFixed(0)}%` : "—"}
          </span>
        </td>

        <td className="whitespace-nowrap px-6 py-4 text-right">
          <div className="inline-flex rounded-lg border border-slate-200 p-1 text-slate-400 transition hover:bg-slate-100 hover:text-slate-700">
            {expanded ? (
              <ChevronUp className="h-4 w-4" />
            ) : (
              <ChevronDown className="h-4 w-4" />
            )}
          </div>
        </td>
      </tr>

      {/* Expanded Hourly Grid mapped inside a single table row that spans all 5 columns */}
      {expanded && (
        <tr>
          <td colSpan={5} className="bg-slate-50/80 p-0 shadow-inner">
            <div className="border-t border-slate-100 px-6 py-6">
              <p className="mb-4 text-xs font-semibold uppercase tracking-wider text-slate-500">
                Hourly Breakdown
              </p>
              <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-6">
                {day.hours.map((hour) => (
                  <HourCard key={hour.hour} hour={hour.hour} status={hour.status} />
                ))}
              </div>
            </div>
          </td>
        </tr>
      )}
    </>
  );
}

function HourCard({ hour, status }: { hour: number; status: AttendanceStatus }) {
  const isPresent = status === "present";
  const isAbsent = status === "absent";

  return (
    <div
      className={`relative overflow-hidden rounded-xl border p-4 transition-all hover:-translate-y-0.5 hover:shadow-sm ${isPresent
          ? "border-emerald-200 bg-emerald-50"
          : isAbsent
            ? "border-red-200 bg-red-50"
            : "border-slate-200 bg-white"
        }`}
    >
      <div className="flex items-center justify-between">
        <span className="text-xs font-bold text-slate-500">Hour {hour}</span>
        {isPresent && <CheckCircle2 className="h-4 w-4 text-emerald-600" />}
        {isAbsent && <XCircle className="h-4 w-4 text-red-600" />}
        {!isPresent && !isAbsent && <Clock3 className="h-4 w-4 text-slate-400" />}
      </div>

      <p
        className={`mt-2 text-sm font-semibold ${isPresent
            ? "text-emerald-700"
            : isAbsent
              ? "text-red-700"
              : "text-slate-500"
          }`}
      >
        {isPresent ? "Present" : isAbsent ? "Absent" : "N/A"}
      </p>
    </div>
  );
}

// ----------------------------------------------------------------------
// Utils
// ----------------------------------------------------------------------

function parseDate(date: string): Date {
  const [day, month, year] = date.split("/").map(Number);
  return new Date(year, month - 1, day);
}

function formatDate(date: string): string {
  const parsed = parseDate(date);
  return parsed.toLocaleDateString("en-IN", {
    day: "2-digit",
    month: "short",
    year: "numeric",
    weekday: "short",
  });
}