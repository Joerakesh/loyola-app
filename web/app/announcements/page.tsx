"use client";

import { useEffect, useState } from "react";
import {
    Download,
    ExternalLink,
    FileText,
    Megaphone,
    Newspaper,
} from "lucide-react";

import AppShell from "../../components/layout/app-shell";
import { getAnnouncements } from "../../lib/api/website";
import type { WebsiteAnnouncement } from "../../types/api";

export default function AnnouncementsPage() {
    const [announcements, setAnnouncements] = useState<
        WebsiteAnnouncement[]
    >([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        let cancelled = false;

        async function loadAnnouncements() {
            try {
                setLoading(true);
                setError(null);

                const response = await getAnnouncements();

                if (response.status !== "success") {
                    throw new Error("Unable to load announcements");
                }

                if (!cancelled) {
                    setAnnouncements(response.data ?? []);
                }
            } catch (err) {
                console.error(err);

                if (!cancelled) {
                    setError(
                        err instanceof Error
                            ? err.message
                            : "Unable to load announcements",
                    );
                }
            } finally {
                if (!cancelled) {
                    setLoading(false);
                }
            }
        }

        loadAnnouncements();

        return () => {
            cancelled = true;
        };
    }, []);

    if (loading) {
        return (
            <AppShell>
                <div className="flex min-h-[60vh] items-center justify-center">
                    <div className="flex items-center gap-3 text-slate-500">
                        <div className="h-5 w-5 animate-spin rounded-full border-2 border-slate-300 border-t-[#8b0000]" />
                        Loading announcements...
                    </div>
                </div>
            </AppShell>
        );
    }

    if (error) {
        return (
            <AppShell>
                <div className="rounded-2xl border border-red-200 bg-red-50 p-6 text-red-700">
                    <h2 className="font-semibold">
                        Unable to load announcements
                    </h2>
                    <p className="mt-1 text-sm">{error}</p>
                </div>
            </AppShell>
        );
    }

    return (
        <AppShell>
            <div className="mx-auto max-w-4xl space-y-8">
                <section>
                    <div className="flex flex-col justify-between gap-4 md:flex-row md:items-end">
                        <div>
                            <p className="text-sm font-medium text-[#8b0000]">
                                Loyola College
                            </p>

                            <h1 className="mt-1 text-3xl font-bold tracking-tight md:text-4xl">
                                Announcements
                            </h1>

                            <p className="mt-2 text-slate-500">
                                Latest circulars published on the college
                                website.
                            </p>
                        </div>

                        <div className="flex items-center gap-2 text-sm text-slate-500">
                            <Megaphone size={17} />
                            {announcements.length} announcement
                            {announcements.length === 1 ? "" : "s"}
                        </div>
                    </div>
                </section>

                {announcements.length === 0 ? (
                    <div className="rounded-2xl border border-dashed border-slate-300 bg-white p-12 text-center">
                        <Newspaper
                            size={36}
                            className="mx-auto text-slate-300"
                        />
                        <h2 className="mt-4 font-semibold">
                            No announcements right now
                        </h2>
                        <p className="mt-1 text-sm text-slate-500">
                            Check back later — new circulars appear here
                            automatically.
                        </p>
                    </div>
                ) : (
                    <section className="space-y-4">
                        {announcements.map((item) => (
                            <AnnouncementCard key={item.id} item={item} />
                        ))}
                    </section>
                )}
            </div>
        </AppShell>
    );
}

function AnnouncementCard({ item }: { item: WebsiteAnnouncement }) {
    const attachment = item.attachment;

    return (
        <article className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm transition hover:border-slate-300 hover:shadow-md">
            <div className="flex flex-col gap-4 sm:flex-row sm:items-start">
                <div className="rounded-xl bg-[#8b0000]/5 p-3 text-[#8b0000]">
                    <FileText size={20} />
                </div>

                <div className="min-w-0 flex-1">
                    <a
                        href={item.url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="font-semibold leading-snug text-slate-900 transition hover:text-[#8b0000]"
                    >
                        {item.title}
                    </a>

                    <div className="mt-3 flex flex-wrap items-center gap-2">
                        {attachment ? (
                            <>
                                <span className="inline-flex items-center gap-1 rounded-md bg-red-50 px-2 py-1 text-xs font-semibold uppercase tracking-wide text-[#8b0000]">
                                    <FileText size={13} />
                                    {attachment.type === "pdf"
                                        ? "PDF"
                                        : attachment.type}
                                </span>

                                <a
                                    href={attachment.url}
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    className="inline-flex items-center gap-1.5 rounded-md bg-slate-900 px-3 py-1.5 text-xs font-semibold text-white transition hover:bg-slate-700"
                                >
                                    <Download size={14} />
                                    Download
                                </a>
                            </>
                        ) : (
                            <a
                                href={item.url}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="inline-flex items-center gap-1.5 rounded-md bg-slate-100 px-3 py-1.5 text-xs font-semibold text-slate-700 transition hover:bg-slate-200"
                            >
                                <ExternalLink size={14} />
                                View
                            </a>
                        )}
                    </div>
                </div>
            </div>
        </article>
    );
}