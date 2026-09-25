"use client";

import { useEffect, useState } from "react";
import {
    Activity,
    ArrowUpRight,
    CalendarDays,
    CheckCircle2,
    Clock,
    CreditCard,
    Download,
    FileText,
    GraduationCap,
    Megaphone,
    TrendingUp,
    UserRound,
} from "lucide-react";

import AppShell from "../../components/layout/app-shell";
import { getBootstrap } from "../../lib/api/erp";

import type {
    AttendanceDay,
    AttendanceHour,
    BootstrapData,
    WebsiteAnnouncement,
} from "../../types/api";

function formatDay(dateKey: string): string {
    return new Date(`${dateKey}T00:00:00`).toLocaleDateString("en-IN", {
        weekday: "short",
        day: "numeric",
        month: "short",
    });
}

export default function DashboardPage() {
    const [data, setData] = useState<BootstrapData | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        async function load() {
            try {
                setLoading(true);
                setError(null);

                // Single call — LRMS session is cached server-side, so this is
                // one login + parallel data fetches, then one round trip here.
                const response = await getBootstrap();

                if (response.status !== "success") {
                    throw new Error("Unable to load dashboard");
                }

                setData(response.data);
            } catch (err) {
                console.error(err);

                setError(
                    err instanceof Error
                        ? err.message
                        : "Unable to load dashboard",
                );
            } finally {
                setLoading(false);
            }
        }

        load();
    }, []);

    if (loading) {
        return (
            <AppShell>
                <div className="flex min-h-[60vh] items-center justify-center">
                    <div className="flex items-center gap-3 text-slate-500">
                        <div className="h-5 w-5 animate-spin rounded-full border-2 border-slate-300 border-t-[#8b0000]" />
                        Loading dashboard...
                    </div>
                </div>
            </AppShell>
        );
    }

    if (error) {
        return (
            <AppShell>
                <div className="rounded-2xl border border-red-200 bg-red-50 p-6 text-red-700">
                    <h2 className="font-semibold">Unable to load dashboard</h2>
                    <p className="mt-1 text-sm">{error}</p>
                </div>
            </AppShell>
        );
    }

    const student = data?.student;
    const summary = data?.attendance.summary;
    const last6Days = data?.attendance.last6Days ?? [];
    const announcements = data?.announcements ?? [];

    return (
        <AppShell>
            <div className="mx-auto max-w-7xl space-y-8">
                <section>
                    <div className="flex flex-col justify-between gap-4 md:flex-row md:items-end">
                        <div>
                            <p className="text-sm font-medium text-[#8b0000]">
                                Student Portal
                            </p>

                            <h1 className="mt-1 text-3xl font-bold tracking-tight md:text-4xl">
                                Welcome back{student?.name ? `, ${student.name}` : ""} 👋
                            </h1>

                            <p className="mt-2 text-slate-500">
                                Here&apos;s your academic overview.
                            </p>
                        </div>

                        <div className="flex items-center gap-2 text-sm text-slate-500">
                            <CalendarDays size={17} />
                            Academic Dashboard
                        </div>
                    </div>
                </section>

                <section className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
                    <StatCard
                        title="Attendance"
                        value={summary ? `${summary.attendancePercentage}%` : "—"}
                        description="Overall attendance"
                        icon={<Activity size={20} />}
                    />

                    <StatCard
                        title="Classes Present"
                        value={summary ? String(summary.present) : "—"}
                        description="Recorded classes"
                        icon={<CheckCircle2 size={20} />}
                    />

                    <StatCard
                        title="Classes Absent"
                        value={summary ? String(summary.absent) : "—"}
                        description="Recorded absences"
                        icon={<Clock size={20} />}
                    />

                    <StatCard
                        title="Fees Paid"
                        value={
                            data
                                ? `₹${data.fees.totalPaid.toLocaleString("en-IN")}`
                                : "—"
                        }
                        description="Total paid"
                        icon={<CreditCard size={20} />}
                    />
                </section>

                <section className="grid gap-6 lg:grid-cols-3">
                    <div className="rounded-3xl bg-[#8b0000] p-7 text-white shadow-lg lg:col-span-2">
                        <div className="flex items-start justify-between">
                            <div>
                                <div className="flex items-center gap-2 text-sm text-white/70">
                                    <TrendingUp size={17} />
                                    Attendance overview
                                </div>

                                <div className="mt-4 text-5xl font-bold">
                                    {summary ? `${summary.attendancePercentage}%` : "—"}
                                </div>

                                <p className="mt-2 text-sm text-white/70">
                                    Keep your attendance above the required minimum.
                                </p>
                            </div>

                            <div className="rounded-2xl bg-white/10 p-3">
                                <Activity size={25} />
                            </div>
                        </div>

                        <div className="mt-8">
                            <div className="h-3 overflow-hidden rounded-full bg-white/20">
                                <div
                                    className="h-full rounded-full bg-white transition-all"
                                    style={{
                                        width: `${Math.min(
                                            summary?.attendancePercentage ?? 0,
                                            100,
                                        )}%`,
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

                    <div className="rounded-3xl border border-slate-200 bg-white p-7 shadow-sm">
                        <div className="flex items-center gap-3">
                            <div className="rounded-xl bg-slate-100 p-3">
                                <UserRound size={21} />
                            </div>

                            <div>
                                <h2 className="font-semibold">Student Profile</h2>
                                <p className="text-xs text-slate-500">
                                    Personal information
                                </p>
                            </div>
                        </div>

                        <div className="mt-6 space-y-4">
                            <InfoRow
                                label="Name"
                                value={student?.name || "—"}
                            />

                            <InfoRow
                                label="Email"
                                value={student?.email || "—"}
                            />

                            <InfoRow
                                label="Mobile"
                                value={student?.mobile || "—"}
                            />
                        </div>

                        <a
                            href="/profile"
                            className="mt-6 flex items-center justify-between rounded-xl bg-slate-50 px-4 py-3 text-sm font-medium hover:bg-slate-100"
                        >
                            View profile
                            <ArrowUpRight size={17} />
                        </a>
                    </div>
                </section>

                <section className="grid gap-6 lg:grid-cols-2">
                    <RecentAttendance days={last6Days} />

                    <AnnouncementsPanel announcements={announcements} />
                </section>

                <section>
                    <div className="mb-4 flex items-center justify-between">
                        <div>
                            <h2 className="text-xl font-bold">Quick access</h2>
                            <p className="text-sm text-slate-500">
                                Frequently used sections
                            </p>
                        </div>
                    </div>

                    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
                        <QuickCard
                            href="/attendance"
                            icon={<Activity size={22} />}
                            title="Attendance"
                            description="View attendance details"
                        />

                        <QuickCard
                            href="/subjects"
                            icon={<GraduationCap size={22} />}
                            title="Subjects"
                            description="View enrolled subjects"
                        />

                        <QuickCard
                            href="/marks"
                            icon={<TrendingUp size={22} />}
                            title="Marks"
                            description="View internal marks"
                        />

                        <QuickCard
                            href="/fees"
                            icon={<CreditCard size={22} />}
                            title="Fees"
                            description="View fee information"
                        />
                    </div>
                </section>
            </div>
        </AppShell>
    );
}

function RecentAttendance({ days }: { days: AttendanceDay[] }) {
    return (
        <div className="rounded-3xl border border-slate-200 bg-white p-7 shadow-sm">
            <div className="flex items-center justify-between">
                <div>
                    <h2 className="font-semibold">Recent attendance</h2>
                    <p className="text-xs text-slate-500">
                        Your last {days.length || "few"} class days
                    </p>
                </div>

                <a
                    href="/attendance"
                    className="rounded-xl bg-slate-50 px-3 py-2 text-xs font-semibold text-slate-600 transition hover:bg-slate-100"
                >
                    View all
                </a>
            </div>

            {days.length === 0 ? (
                <div className="mt-6 rounded-2xl border border-dashed border-slate-300 p-8 text-center text-sm text-slate-500">
                    No recent attendance recorded yet.
                </div>
            ) : (
                <ul className="mt-5 divide-y divide-slate-100">
                    {days.map((day) => (
                        <li
                            key={day.date}
                            className="flex items-center justify-between gap-4 py-4 first:pt-0 last:pb-0"
                        >
                            <div className="min-w-0">
                                <div className="font-medium text-slate-900">
                                    {formatDay(day.date)}
                                </div>
                                <div className="mt-0.5 text-xs text-slate-500">
                                    {day.dayOrder !== null
                                        ? `Day-${day.dayOrder}`
                                        : "No day order"}
                                </div>
                            </div>

                            <div className="flex items-center gap-1.5">
                                {day.hours.map((hour) => (
                                    <HourBadge key={hour.hour} hour={hour} />
                                ))}
                            </div>
                        </li>
                    ))}
                </ul>
            )}
        </div>
    );
}

function HourBadge({ hour }: { hour: AttendanceHour }) {
    const styles: Record<AttendanceHour["status"], string> = {
        present: "bg-emerald-100 text-emerald-700",
        absent: "bg-red-100 text-red-600",
        not_scheduled: "bg-slate-100 text-slate-300",
    };

    const label: Record<AttendanceHour["status"], string> = {
        present: "P",
        absent: "A",
        not_scheduled: "·",
    };

    return (
        <span
            title={`Hour ${hour.hour}: ${hour.status.replace("_", " ")}`}
            className={`inline-flex h-7 w-7 items-center justify-center rounded-lg text-xs font-bold ${styles[hour.status]}`}
        >
            {label[hour.status]}
        </span>
    );
}

function AnnouncementsPanel({
    announcements,
}: {
    announcements: WebsiteAnnouncement[];
}) {
    const visible = announcements.slice(0, 4);

    return (
        <div className="rounded-3xl border border-slate-200 bg-white p-7 shadow-sm">
            <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                    <div className="rounded-xl bg-[#8b0000]/5 p-3 text-[#8b0000]">
                        <Megaphone size={21} />
                    </div>

                    <div>
                        <h2 className="font-semibold">Announcements</h2>
                        <p className="text-xs text-slate-500">
                            Latest from the college website
                        </p>
                    </div>
                </div>

                <a
                    href="/announcements"
                    className="rounded-xl bg-slate-50 px-3 py-2 text-xs font-semibold text-slate-600 transition hover:bg-slate-100"
                >
                    View all
                </a>
            </div>

            {visible.length === 0 ? (
                <div className="mt-6 rounded-2xl border border-dashed border-slate-300 p-8 text-center text-sm text-slate-500">
                    No announcements right now.
                </div>
            ) : (
                <ul className="mt-5 space-y-3">
                    {visible.map((item) => (
                        <li
                            key={item.id}
                            className="flex items-start gap-3 rounded-2xl border border-slate-100 p-3 transition hover:border-slate-200"
                        >
                            <div className="rounded-lg bg-red-50 p-2 text-[#8b0000]">
                                <FileText size={16} />
                            </div>

                            <div className="min-w-0 flex-1">
                                <a
                                    href={item.url}
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    className="line-clamp-2 text-sm font-medium leading-snug text-slate-900 transition hover:text-[#8b0000]"
                                >
                                    {item.title}
                                </a>

                                {item.attachment && (
                                    <a
                                        href={item.attachment.url}
                                        target="_blank"
                                        rel="noopener noreferrer"
                                        className="mt-2 inline-flex items-center gap-1.5 rounded-md bg-slate-900 px-2.5 py-1 text-xs font-semibold text-white transition hover:bg-slate-700"
                                    >
                                        <Download size={13} />
                                        PDF
                                    </a>
                                )}
                            </div>
                        </li>
                    ))}
                </ul>
            )}
        </div>
    );
}

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
        <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
            <div className="flex items-center justify-between">
                <div className="text-sm font-medium text-slate-500">
                    {title}
                </div>

                <div className="rounded-xl bg-slate-100 p-2.5 text-slate-600">
                    {icon}
                </div>
            </div>

            <div className="mt-4 text-3xl font-bold">{value}</div>

            <div className="mt-1 text-xs text-slate-500">
                {description}
            </div>
        </div>
    );
}

function InfoRow({
    label,
    value,
}: {
    label: string;
    value: string;
}) {
    return (
        <div>
            <div className="text-xs text-slate-400">{label}</div>
            <div className="mt-1 truncate text-sm font-medium">
                {value}
            </div>
        </div>
    );
}

function QuickCard({
    href,
    icon,
    title,
    description,
}: {
    href: string;
    icon: React.ReactNode;
    title: string;
    description: string;
}) {
    return (
        <a
            href={href}
            className="group rounded-2xl border border-slate-200 bg-white p-5 shadow-sm transition hover:-translate-y-0.5 hover:border-slate-300 hover:shadow-md"
        >
            <div className="flex items-center justify-between">
                <div className="rounded-xl bg-slate-100 p-3 text-slate-700">
                    {icon}
                </div>

                <ArrowUpRight
                    size={18}
                    className="text-slate-400 transition group-hover:text-slate-700"
                />
            </div>

            <h3 className="mt-5 font-semibold">{title}</h3>

            <p className="mt-1 text-sm text-slate-500">
                {description}
            </p>
        </a>
    );
}