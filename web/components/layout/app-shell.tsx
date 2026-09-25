"use client";

import {
  BarChart3,
  BookOpen,
  CalendarDays,
  CalendarRange,
  CircleUserRound,
  CreditCard,
  GraduationCap,
  LayoutDashboard,
  LogOut,
  Megaphone,
  Menu,
  X,
} from "lucide-react";
import { useState } from "react";

interface AppShellProps {
  children: React.ReactNode;
}

const navigation = [
  {
    label: "Dashboard",
    href: "/dashboard",
    icon: LayoutDashboard,
  },
  {
    label: "Announcements",
    href: "/announcements",
    icon: Megaphone,
  },
  {
    label: "Calendar",
    href: "/calendar",
    icon: CalendarRange,
  },
  {
    label: "Attendance",
    href: "/attendance",
    icon: BarChart3,
  },
  {
    label: "Subjects",
    href: "/subjects",
    icon: BookOpen,
  },
  {
    label: "Marks",
    href: "/marks",
    icon: GraduationCap,
  },
  {
    label: "Timetable",
    href: "/timetable",
    icon: CalendarDays,
  },
  {
    label: "Fees",
    href: "/fees",
    icon: CreditCard,
  },
  {
    label: "Profile",
    href: "/profile",
    icon: CircleUserRound,
  },
];

export default function AppShell({ children }: AppShellProps) {
  const [mobileOpen, setMobileOpen] = useState(false);

  return (
    <div className="min-h-screen bg-[#f5f7fa] text-slate-900">
      <aside
        className={[
          "fixed inset-y-0 left-0 z-50 w-72 border-r border-slate-200",
          "bg-white transition-transform duration-300",
          mobileOpen ? "translate-x-0" : "-translate-x-full",
          "lg:translate-x-0",
        ].join(" ")}
      >
        <div className="flex h-full flex-col">
          <div className="flex h-20 items-center justify-between border-b border-slate-200 px-6">
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-[#8b0000] text-white">
                <GraduationCap size={22} />
              </div>

              <div>
                <div className="font-semibold">Loyola ERP</div>
                <div className="text-xs text-slate-500">
                  Student Portal
                </div>
              </div>
            </div>

            <button
              onClick={() => setMobileOpen(false)}
              className="rounded-lg p-2 hover:bg-slate-100 lg:hidden"
              aria-label="Close navigation"
            >
              <X size={20} />
            </button>
          </div>

          <nav className="flex-1 space-y-1 p-4">
            {navigation.map((item) => {
              const Icon = item.icon;

              return (
                <a
                  key={item.href}
                  href={item.href}
                  onClick={() => setMobileOpen(false)}
                  className="flex items-center gap-3 rounded-xl px-4 py-3 text-sm font-medium text-slate-600 transition hover:bg-slate-100 hover:text-slate-900"
                >
                  <Icon size={19} />
                  {item.label}
                </a>
              );
            })}
          </nav>

          <div className="border-t border-slate-200 p-4">
            <button className="flex w-full items-center gap-3 rounded-xl px-4 py-3 text-sm font-medium text-slate-600 hover:bg-red-50 hover:text-red-700">
              <LogOut size={19} />
              Sign out
            </button>
          </div>
        </div>
      </aside>

      {mobileOpen && (
        <button
          className="fixed inset-0 z-40 bg-black/30 lg:hidden"
          onClick={() => setMobileOpen(false)}
          aria-label="Close navigation overlay"
        />
      )}

      <div className="lg:pl-72">
        <header className="sticky top-0 z-30 flex h-16 items-center border-b border-slate-200 bg-white/90 px-4 backdrop-blur md:px-8">
          <button
            onClick={() => setMobileOpen(true)}
            className="rounded-lg p-2 hover:bg-slate-100 lg:hidden"
            aria-label="Open navigation"
          >
            <Menu size={22} />
          </button>

          <div className="ml-auto flex items-center gap-3">
            <div className="hidden text-right sm:block">
              <div className="text-sm font-semibold">Loyola Student</div>
              <div className="text-xs text-slate-500">
                Student Portal
              </div>
            </div>

            <div className="flex h-9 w-9 items-center justify-center rounded-full bg-slate-200">
              <CircleUserRound size={20} className="text-slate-600" />
            </div>
          </div>
        </header>

        <main className="min-h-[calc(100vh-4rem)] p-4 md:p-8">
          {children}
        </main>
      </div>
    </div>
  );
}
