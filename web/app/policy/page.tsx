"use client";

import { useState } from "react";
import {
    BookOpen,
    Building,
    CheckCircle2,
    FileText,
    Scale,
    ShieldCheck,
    AlertCircle
} from "lucide-react";

import AppShell from "@/components/layout/app-shell"; // Adjust path if needed

// ----------------------------------------------------------------------
// Mock Policy Data
// ----------------------------------------------------------------------

const POLICIES = [
    {
        id: "academic",
        title: "Academic Policies",
        icon: <BookOpen size={18} />,
        lastUpdated: "August 12, 2026",
        content: (
            <div className="space-y-6 text-slate-600">
                <section>
                    <h3 className="text-lg font-bold text-slate-900">1. Attendance Requirements</h3>
                    <p className="mt-2 text-sm leading-relaxed">
                        Students are required to maintain a minimum of <strong>75% attendance</strong> in all enrolled subjects. Failure to meet this requirement may result in the inability to appear for the end-semester examinations. Medical leaves must be supported by valid documentation submitted within 3 working days.
                    </p>
                </section>

                <section>
                    <h3 className="text-lg font-bold text-slate-900">2. Academic Integrity</h3>
                    <p className="mt-2 text-sm leading-relaxed">
                        Strict adherence to academic honesty is expected. Plagiarism, cheating during examinations, or submitting unoriginal work will lead to immediate disciplinary action, including but not limited to failing the assignment or course.
                    </p>
                </section>

                <section>
                    <h3 className="text-lg font-bold text-slate-900">3. Examination Conduct</h3>
                    <ul className="mt-2 list-inside list-disc space-y-2 text-sm">
                        <li>ID cards are mandatory for entry into the examination hall.</li>
                        <li>Electronic devices, including smartwatches and mobile phones, are strictly prohibited.</li>
                        <li>Students must arrive at least 15 minutes prior to the commencement of the exam.</li>
                    </ul>
                </section>
            </div>
        ),
    },
    {
        id: "privacy",
        title: "Privacy Policy",
        icon: <ShieldCheck size={18} />,
        lastUpdated: "September 15, 2026",
        content: (
            <div className="space-y-6 text-slate-600">
                <section>
                    <h3 className="text-lg font-bold text-slate-900">Information We Collect</h3>
                    <p className="mt-2 text-sm leading-relaxed">
                        When you log in using Google OAuth, we collect your primary Google email address and basic profile information (such as your name). We also collect and store academic data, including attendance records, internal marks, and fee payment status, strictly for educational administration.
                    </p>
                </section>

                <section>
                    <h3 className="text-lg font-bold text-slate-900">How We Use Your Data</h3>
                    <p className="mt-2 text-sm leading-relaxed">
                        The data collected is used exclusively to:
                    </p>
                    <ul className="mt-2 list-inside list-disc space-y-2 text-sm">
                        <li>Authenticate your identity and secure your account access.</li>
                        <li>Display personalized academic dashboards, attendance logs, and examination results.</li>
                        <li>Process institutional requests, such as hostel leave approvals.</li>
                    </ul>
                </section>

                <section>
                    <h3 className="text-lg font-bold text-slate-900">Information Sharing & Storage</h3>
                    <p className="mt-2 text-sm leading-relaxed">
                        We do not sell, rent, or share your personal data or Google user data with any third parties. All data is encrypted and securely stored in our ERP systems. Your data is retained only for the duration of your enrollment and institutional requirements.
                    </p>
                    <div className="mt-4 flex items-start gap-3 rounded-xl border border-emerald-200 bg-emerald-50 p-4">
                        <CheckCircle2 className="mt-0.5 h-5 w-5 shrink-0 text-emerald-600" />
                        <p className="text-sm text-emerald-800">
                            Your profile data, passwords, and local storage are secured using industry-standard encryption protocols.
                        </p>
                    </div>
                </section>
            </div>
        ),
    },
    {
        id: "hostel",
        title: "Hostel Regulations",
        icon: <Building size={18} />,
        lastUpdated: "July 20, 2026",
        content: (
            <div className="space-y-6 text-slate-600">
                <section>
                    <h3 className="text-lg font-bold text-slate-900">In-Time & Out-Time</h3>
                    <p className="mt-2 text-sm leading-relaxed">
                        All hostel residents must adhere to the prescribed curfew timings. The standard reporting time is 8:00 PM unless prior permission has been granted via the Hostel Management System.
                    </p>
                </section>

                <section>
                    <h3 className="text-lg font-bold text-slate-900">Leave Requests</h3>
                    <p className="mt-2 text-sm leading-relaxed">
                        Outstation leaves must be applied for at least 24 hours in advance through the portal. The request requires digital approval from both the respective warden and the designated parent/guardian.
                    </p>
                </section>
            </div>
        ),
    },
    {
        id: "terms",
        title: "Terms of Use",
        icon: <Scale size={18} />,
        lastUpdated: "January 15, 2026",
        content: (
            <div className="space-y-6 text-slate-600">
                <section>
                    <h3 className="text-lg font-bold text-slate-900">Portal Usage</h3>
                    <p className="mt-2 text-sm leading-relaxed">
                        The student portal and mobile applications provided by the institution are intended solely for academic and administrative tracking. Any attempt to exploit, reverse engineer, or manipulate the ERP system will result in immediate suspension of access.
                    </p>
                </section>

                <div className="mt-4 flex items-start gap-3 rounded-xl border border-amber-200 bg-amber-50 p-4">
                    <AlertCircle className="mt-0.5 h-5 w-5 shrink-0 text-amber-600" />
                    <p className="text-sm text-amber-800">
                        By logging into this system, you acknowledge that you have read and agreed to abide by all institutional rules and regulations.
                    </p>
                </div>
            </div>
        ),
    },
];

// ----------------------------------------------------------------------
// Main Component
// ----------------------------------------------------------------------

export default function PolicyPage() {
    const [activeTab, setActiveTab] = useState(POLICIES[0].id);

    const activePolicy = POLICIES.find((p) => p.id === activeTab) || POLICIES[0];

    return (
        <AppShell>
            <div className="mx-auto max-w-7xl space-y-8">
                {/* Header Section */}
                <section>
                    <div className="flex flex-col justify-between gap-4 md:flex-row md:items-end">
                        <div>
                            <p className="text-sm font-medium text-[#8b0000]">
                                Rules & Regulations
                            </p>
                            <h1 className="mt-1 text-3xl font-bold tracking-tight md:text-4xl">
                                Policies & Terms
                            </h1>
                            <p className="mt-2 text-slate-500">
                                Review the institutional guidelines, privacy agreements, and terms of service.
                            </p>
                        </div>

                        <div className="flex items-center gap-2 text-sm text-slate-500">
                            <FileText size={17} />
                            Policy Document
                        </div>
                    </div>
                </section>

                {/* Content Layout Grid */}
                <section className="grid gap-8 lg:grid-cols-[280px_1fr]">

                    {/* Sidebar Navigation */}
                    <div className="flex flex-col gap-2">
                        {POLICIES.map((policy) => {
                            const isActive = activeTab === policy.id;

                            return (
                                <button
                                    key={policy.id}
                                    onClick={() => setActiveTab(policy.id)}
                                    className={`flex items-center justify-between rounded-xl px-4 py-3 text-left transition-all ${isActive
                                        ? "bg-red-50 text-[#8b0000] ring-1 ring-[#8b0000]/20"
                                        : "text-slate-600 hover:bg-slate-100 hover:text-slate-900"
                                        }`}
                                >
                                    <div className="flex items-center gap-3">
                                        <div className={`${isActive ? "text-[#8b0000]" : "text-slate-400"}`}>
                                            {policy.icon}
                                        </div>
                                        <span className="font-medium">{policy.title}</span>
                                    </div>
                                </button>
                            );
                        })}
                    </div>

                    {/* Active Policy Content Area */}
                    <div className="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm sm:p-10">
                        <div className="mb-8 border-b border-slate-100 pb-8">
                            <div className="flex items-center gap-3 text-[#8b0000]">
                                {activePolicy.icon}
                                <h2 className="text-2xl font-bold text-slate-900">
                                    {activePolicy.title}
                                </h2>
                            </div>
                            <p className="mt-2 text-sm text-slate-500">
                                Last updated on {activePolicy.lastUpdated}
                            </p>
                        </div>

                        {/* Render Content */}
                        <div className="prose-sm sm:prose-base max-w-none">
                            {activePolicy.content}
                        </div>

                        {/* Footer Acknowledgment (Visual only) */}
                        <div className="mt-12 flex items-center justify-between rounded-2xl bg-slate-50 p-5">
                            <div className="text-sm text-slate-500">
                                Questions about these policies? Contact administration.
                            </div>
                            <button className="rounded-xl bg-slate-900 px-5 py-2 text-sm font-medium text-white transition hover:bg-slate-800">
                                Download PDF
                            </button>
                        </div>
                    </div>
                </section>
            </div>
        </AppShell>
    );
}