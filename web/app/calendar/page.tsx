"use client";

import { useEffect, useMemo, useState } from "react";
import {
  CalendarRange,
  ChevronLeft,
  ChevronRight,
  CircleDot,
  LayoutGrid,
  List,
} from "lucide-react";

import AppShell from "../../components/layout/app-shell";
import { getCalendar } from "../../lib/api/calendar";
import type { CalendarEvent } from "../../types/api";

const MONTH_NAMES = [
  "January",
  "February",
  "March",
  "April",
  "May",
  "June",
  "July",
  "August",
  "September",
  "October",
  "November",
  "December",
];

const MONTH_SHORT = [
  "Jan",
  "Feb",
  "Mar",
  "Apr",
  "May",
  "Jun",
  "Jul",
  "Aug",
  "Sep",
  "Oct",
  "Nov",
  "Dec",
];

const WEEKDAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

function pad(value: number): string {
  return String(value).padStart(2, "0");
}

function isoDate(year: number, month: number, day: number): string {
  return `${year}-${pad(month)}-${pad(day)}`;
}

function todayIso(): string {
  const now = new Date();

  return isoDate(
    now.getUTCFullYear(),
    now.getUTCMonth() + 1,
    now.getUTCDate(),
  );
}

function parseMonthKey(monthKey: string): { year: number; month: number } {
  const [year, month] = monthKey.split("-").map(Number);

  return { year, month };
}

function shiftMonth(monthKey: string, delta: number): string {
  const { year, month } = parseMonthKey(monthKey);
  const shifted = new Date(Date.UTC(year, month - 1 + delta, 1));

  return `${shifted.getUTCFullYear()}-${pad(shifted.getUTCMonth() + 1)}`;
}

function addDays(dayKey: string, delta: number): string {
  const [year, month, day] = dayKey.split("-").map(Number);
  const shifted = new Date(Date.UTC(year, month - 1, day + delta));

  return isoDate(
    shifted.getUTCFullYear(),
    shifted.getUTCMonth() + 1,
    shifted.getUTCDate(),
  );
}

function mondayOf(dayKey: string): string {
  const [year, month, day] = dayKey.split("-").map(Number);
  const date = new Date(Date.UTC(year, month - 1, day));
  const offset = (date.getUTCDay() + 6) % 7;

  return addDays(dayKey, -offset);
}

function monthCells(monthKey: string): Array<string | null> {
  const { year, month } = parseMonthKey(monthKey);
  const daysInMonth = new Date(Date.UTC(year, month, 0)).getUTCDate();
  const startOffset =
    (new Date(Date.UTC(year, month - 1, 1)).getUTCDay() + 6) % 7;

  const cells: Array<string | null> = [];

  for (let i = 0; i < startOffset; i++) {
    cells.push(null);
  }

  for (let day = 1; day <= daysInMonth; day++) {
    cells.push(isoDate(year, month, day));
  }

  while (cells.length % 7 !== 0) {
    cells.push(null);
  }

  return cells;
}

function weekDayKeys(mondayKey: string): string[] {
  return WEEKDAYS.map((_label, index) => addDays(mondayKey, index));
}

function weekdayLabel(dateKey: string): string {
  const [year, month, day] = dateKey.split("-").map(Number);
  const weekday = new Date(Date.UTC(year, month - 1, day)).getUTCDay();

  // getUTCDay: Sun=0 … Sat=6 → rebase onto the Monday-based WEEKDAYS array.
  return WEEKDAYS[(weekday + 6) % 7];
}

function formatShort(dateKey: string): string {
  const [, month, day] = dateKey.split("-").map(Number);

  return `${MONTH_SHORT[month - 1]} ${day}`;
}

export default function CalendarPage() {
  const [view, setView] = useState<"month" | "week">("month");
  const [anchorMonth, setAnchorMonth] = useState(() =>
    todayIso().slice(0, 7),
  );
  const [anchorWeek, setAnchorWeek] = useState(() => mondayOf(todayIso()));

  const [events, setEvents] = useState<CalendarEvent[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function load() {
      try {
        setLoading(true);
        setError(null);

        const query =
          view === "month" ? { month: anchorMonth } : { week: anchorWeek };
        const response = await getCalendar(query);

        if (response.status !== "success") {
          throw new Error("Unable to load calendar");
        }

        if (!cancelled) {
          setEvents(response.data ?? []);
        }
      } catch (err) {
        console.error(err);

        if (!cancelled) {
          setError(
            err instanceof Error ? err.message : "Unable to load calendar",
          );
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    load();

    return () => {
      cancelled = true;
    };
  }, [view, anchorMonth, anchorWeek]);

  const byDate = useMemo(() => {
    const map = new Map<string, CalendarEvent>();

    for (const event of events) {
      map.set(event.date, event);
    }

    return map;
  }, [events]);

  const today = todayIso();

  const headerLabel =
    view === "month"
      ? (() => {
          const { year, month } = parseMonthKey(anchorMonth);

          return `${MONTH_NAMES[month - 1]} ${year}`;
        })()
      : (() => {
          const days = weekDayKeys(anchorWeek);

          return `${formatShort(days[0])} – ${formatShort(days[6])}, ${days[6].slice(0, 4)}`;
        })();

  function goPrevious() {
    if (view === "month") {
      setAnchorMonth(shiftMonth(anchorMonth, -1));
    } else {
      setAnchorWeek(addDays(anchorWeek, -7));
    }
  }

  function goNext() {
    if (view === "month") {
      setAnchorMonth(shiftMonth(anchorMonth, 1));
    } else {
      setAnchorWeek(addDays(anchorWeek, 7));
    }
  }

  function goToday() {
    setAnchorMonth(todayIso().slice(0, 7));
    setAnchorWeek(mondayOf(todayIso()));
  }

  return (
    <AppShell>
      <div className="mx-auto max-w-6xl space-y-6">
        <section>
          <div className="flex flex-col justify-between gap-4 md:flex-row md:items-end">
            <div>
              <p className="text-sm font-medium text-[#8b0000]">
                Loyola College
              </p>

              <h1 className="mt-1 text-3xl font-bold tracking-tight md:text-4xl">
                Academic Calendar
              </h1>

              <p className="mt-2 text-slate-500">
                College events and day orders, synced from the official
                website.
              </p>
            </div>

            <div className="flex items-center gap-2 text-sm text-slate-500">
              <CalendarRange size={17} />
              {events.length} day{events.length === 1 ? "" : "s"} with events
            </div>
          </div>
        </section>

        <section className="flex flex-wrap items-center justify-between gap-3">
          <div className="inline-flex overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
            <ViewToggle
              active={view === "month"}
              icon={<LayoutGrid size={16} />}
              label="Month"
              onClick={() => setView("month")}
            />
            <ViewToggle
              active={view === "week"}
              icon={<List size={16} />}
              label="Week"
              onClick={() => setView("week")}
            />
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={goToday}
              className="rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm font-medium text-slate-700 shadow-sm transition hover:bg-slate-50"
            >
              Today
            </button>

            <button
              onClick={goPrevious}
              aria-label="Previous"
              className="rounded-xl border border-slate-200 bg-white p-2 text-slate-600 shadow-sm transition hover:bg-slate-50"
            >
              <ChevronLeft size={18} />
            </button>

            <div className="min-w-44 rounded-xl border border-slate-200 bg-white px-4 py-2 text-center text-sm font-semibold shadow-sm">
              {headerLabel}
            </div>

            <button
              onClick={goNext}
              aria-label="Next"
              className="rounded-xl border border-slate-200 bg-white p-2 text-slate-600 shadow-sm transition hover:bg-slate-50"
            >
              <ChevronRight size={18} />
            </button>
          </div>
        </section>

        {error ? (
          <div className="rounded-2xl border border-red-200 bg-red-50 p-6 text-red-700">
            <h2 className="font-semibold">Unable to load calendar</h2>
            <p className="mt-1 text-sm">{error}</p>
          </div>
        ) : view === "month" ? (
          <MonthGrid
            monthKey={anchorMonth}
            events={byDate}
            today={today}
            loading={loading}
            hasEvents={events.length > 0}
          />
        ) : (
          <WeekList
            mondayKey={anchorWeek}
            events={byDate}
            today={today}
            loading={loading}
            hasEvents={events.length > 0}
          />
        )}
      </div>
    </AppShell>
  );
}

function ViewToggle({
  active,
  icon,
  label,
  onClick,
}: {
  active: boolean;
  icon: React.ReactNode;
  label: string;
  onClick: () => void;
}) {
  return (
    <button
      onClick={onClick}
      className={[
        "flex items-center gap-2 px-4 py-2 text-sm font-medium transition",
        active
          ? "bg-[#8b0000] text-white"
          : "text-slate-600 hover:bg-slate-50",
      ].join(" ")}
    >
      {icon}
      {label}
    </button>
  );
}

function LoadingState() {
  return (
    <div className="flex min-h-[40vh] items-center justify-center rounded-2xl border border-slate-200 bg-white shadow-sm">
      <div className="flex items-center gap-3 text-slate-500">
        <div className="h-5 w-5 animate-spin rounded-full border-2 border-slate-300 border-t-[#8b0000]" />
        Loading calendar...
      </div>
    </div>
  );
}

function MonthGrid({
  monthKey,
  events,
  today,
  loading,
  hasEvents,
}: {
  monthKey: string;
  events: Map<string, CalendarEvent>;
  today: string;
  loading: boolean;
  hasEvents: boolean;
}) {
  if (loading) {
    return <LoadingState />;
  }

  const cells = monthCells(monthKey);

  return (
    <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
      <div className="grid grid-cols-7 border-b border-slate-200 bg-slate-50 text-center text-xs font-semibold uppercase tracking-wide text-slate-500">
        {WEEKDAYS.map((label) => (
          <div key={label} className="py-2.5">
            {label}
          </div>
        ))}
      </div>

      <div className="grid grid-cols-7">
        {cells.map((dateKey, index) => {
          if (!dateKey) {
            return <div key={`empty-${index}`} className="bg-slate-50/50" />;
          }

          const event = events.get(dateKey);
          const isToday = dateKey === today;

          return (
            <div
              key={dateKey}
              className={[
                "flex min-h-24 flex-col gap-1 border-b border-r border-slate-100 p-1.5 last:border-r-0",
                isToday ? "bg-[#8b0000]/[0.04]" : "",
              ].join(" ")}
            >
              <div className="flex items-start justify-between">
                <span
                  className={[
                    "flex h-6 w-6 items-center justify-center rounded-full text-xs font-bold",
                    isToday
                      ? "bg-[#8b0000] text-white"
                      : "text-slate-700",
                  ].join(" ")}
                >
                  {Number(dateKey.slice(8, 10))}
                </span>

                {event?.dayOrder && (
                  <span className="rounded-md border border-yellow-200 bg-yellow-100 px-1.5 py-0.5 text-[10px] font-semibold text-yellow-800">
                    {event.dayOrder}
                  </span>
                )}
              </div>

              {event?.event ? (
                <p className="line-clamp-2 text-[11px] leading-snug text-slate-600">
                  {event.event}
                </p>
              ) : event ? (
                <div className="flex items-center gap-1 text-slate-400">
                  <CircleDot size={10} />
                  <span className="text-[10px]">No event</span>
                </div>
              ) : null}
            </div>
          );
        })}
      </div>

      {!hasEvents && (
        <div className="border-t border-slate-100 p-4 text-center text-sm text-slate-500">
          No events published for this month yet.
        </div>
      )}
    </div>
  );
}

function WeekList({
  mondayKey,
  events,
  today,
  loading,
  hasEvents,
}: {
  mondayKey: string;
  events: Map<string, CalendarEvent>;
  today: string;
  loading: boolean;
  hasEvents: boolean;
}) {
  if (loading) {
    return <LoadingState />;
  }

  const days = weekDayKeys(mondayKey);

  return (
    <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
      {days.map((dateKey) => {
        const [year, month, day] = dateKey.split("-").map(Number);
        const event = events.get(dateKey);
        const isToday = dateKey === today;

        return (
          <div
            key={dateKey}
            className={[
              "flex flex-col gap-1 border-b border-slate-100 p-4 last:border-b-0 sm:flex-row sm:items-center sm:gap-4",
              isToday ? "bg-[#8b0000]/[0.04]" : "",
            ].join(" ")}
          >
            <div className="flex w-full items-center gap-3 sm:w-40">
              <span
                className={[
                  "flex h-10 w-10 shrink-0 items-center justify-center rounded-xl text-sm font-bold",
                  isToday
                    ? "bg-[#8b0000] text-white"
                    : "bg-slate-100 text-slate-700",
                ].join(" ")}
              >
                {day}
              </span>

              <div>
                <div className="text-xs font-semibold uppercase tracking-wide text-slate-500">
                  {weekdayLabel(dateKey)}
                </div>
                <div className="text-xs text-slate-400">
                  {MONTH_SHORT[month - 1]} {year}
                </div>
              </div>
            </div>

            <div className="flex flex-1 items-center gap-2 sm:gap-3">
              {event?.dayOrder && (
                <span className="shrink-0 rounded-md border border-yellow-200 bg-yellow-100 px-2 py-1 text-[11px] font-semibold text-yellow-800">
                  {event.dayOrder}
                </span>
              )}

              {event?.event ? (
                <p className="text-sm font-medium text-slate-800">
                  {event.event}
                </p>
              ) : (
                <p className="text-sm text-slate-400">No event</p>
              )}
            </div>
          </div>
        );
      })}

      {!hasEvents && (
        <div className="p-4 text-center text-sm text-slate-500">
          No events published for this week.
        </div>
      )}
    </div>
  );
}