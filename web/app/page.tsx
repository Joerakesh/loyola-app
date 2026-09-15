import Link from "next/link";
import { ArrowRight, BookOpen, Building, ShieldCheck, Activity } from "lucide-react";

export default function HomePage() {
  return (
    <div className="flex min-h-screen flex-col bg-slate-50">
      {/* Navigation */}
      <header className="sticky top-0 z-50 border-b border-slate-200 bg-white/80 backdrop-blur-md">
        <div className="mx-auto flex h-16 max-w-7xl items-center justify-between px-6 lg:px-8">
          <div className="flex items-center gap-2 text-[#8b0000]">
            <BookOpen size={24} />
            <span className="text-lg font-bold tracking-tight text-slate-900">
              Campus<span className="text-[#8b0000]">ERP</span>
            </span>
          </div>

          <div className="flex items-center gap-4">
            <Link
              href="/policy"
              className="text-sm font-medium text-slate-500 hover:text-slate-900"
            >
              Privacy Policy
            </Link>
            <Link
              href="/login"
              className="flex items-center gap-2 rounded-xl bg-[#8b0000] px-4 py-2 text-sm font-medium text-white transition hover:bg-[#6a0000]"
            >
              Sign In
            </Link>
          </div>
        </div>
      </header>

      <main className="flex-1">
        {/* Hero Section - Explains the App's Purpose */}
        <section className="relative overflow-hidden bg-white px-6 py-24 lg:px-8">
          <div className="mx-auto max-w-3xl text-center">
            <h1 className="text-4xl font-bold tracking-tight text-slate-900 sm:text-6xl">
              Your Academic Life, <br />
              <span className="text-[#8b0000]">Simplified.</span>
            </h1>
            <p className="mt-6 text-lg leading-8 text-slate-600">
              Welcome to the official Student Portal. This application is designed to help students and faculty seamlessly manage their daily academic activities. Track your attendance, monitor internal marks, request hostel leaves, and view fee structures all in one secure platform.
            </p>
            <div className="mt-10 flex items-center justify-center gap-x-6">
              <Link
                href="/login"
                className="group flex items-center gap-2 rounded-2xl bg-[#8b0000] px-6 py-3.5 text-sm font-semibold text-white shadow-sm transition hover:bg-[#6a0000] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#8b0000]"
              >
                Access Student Portal
                <ArrowRight size={18} className="transition group-hover:translate-x-1" />
              </Link>
              <Link href="/policy" className="text-sm font-semibold leading-6 text-slate-900">
                View our Policies <span aria-hidden="true">→</span>
              </Link>
            </div>
          </div>
        </section>

        {/* Features Section - Further proves to Google what the app does */}
        <section className="mx-auto max-w-7xl px-6 py-20 lg:px-8">
          <div className="mb-12 text-center">
            <h2 className="text-2xl font-bold text-slate-900">Core Features</h2>
            <p className="mt-2 text-slate-500">Everything you need to manage your academic journey.</p>
          </div>

          <div className="grid gap-8 md:grid-cols-3">
            <FeatureCard
              icon={<Activity size={24} />}
              title="Attendance Tracking"
              description="Monitor your daily and hourly attendance records to ensure you meet the 75% academic requirement."
            />
            <FeatureCard
              icon={<Building size={24} />}
              title="Hostel Management"
              description="Digital out-pass system and leave management for hostel residents, complete with digital approvals."
            />
            <FeatureCard
              icon={<ShieldCheck size={24} />}
              title="Secure Data"
              description="Your academic records, internal marks, and personal data are encrypted and stored safely."
            />
          </div>
        </section>
      </main>

      {/* Footer linking to required policy pages */}
      <footer className="border-t border-slate-200 bg-white py-8">
        <div className="mx-auto max-w-7xl px-6 lg:px-8 flex flex-col items-center justify-between gap-4 sm:flex-row">
          <p className="text-sm text-slate-500">
            © {new Date().getFullYear()} CampusERP. All rights reserved.
          </p>
          <div className="flex gap-6 text-sm font-medium text-slate-500">
            <Link href="/policy" className="hover:text-slate-900">Privacy Policy</Link>
            <Link href="/policy" className="hover:text-slate-900">Terms of Service</Link>
          </div>
        </div>
      </footer>
    </div>
  );
}

function FeatureCard({ icon, title, description }: { icon: React.ReactNode, title: string, description: string }) {
  return (
    <div className="rounded-3xl border border-slate-200 bg-white p-8 shadow-sm transition hover:shadow-md">
      <div className="mb-4 inline-flex h-12 w-12 items-center justify-center rounded-2xl bg-red-50 text-[#8b0000]">
        {icon}
      </div>
      <h3 className="mb-2 text-lg font-bold text-slate-900">{title}</h3>
      <p className="text-sm leading-relaxed text-slate-600">{description}</p>
    </div>
  );
}