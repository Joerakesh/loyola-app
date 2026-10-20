"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { BarChart3, BookOpen, CalendarDays, CircleUserRound, CreditCard, GraduationCap, LayoutDashboard, LogOut, Menu, X } from "lucide-react";
import { useState } from "react";

interface AppShellProps { children: React.ReactNode; }
const navigation = [
  { label: "Home", href: "/dashboard", icon: LayoutDashboard },
  { label: "Attendance", href: "/attendance", icon: BarChart3 },
  { label: "Subjects", href: "/subjects", icon: BookOpen },
  { label: "Marks", href: "/marks", icon: GraduationCap },
  { label: "Timetable", href: "/timetable", icon: CalendarDays },
  { label: "Fees", href: "/fees", icon: CreditCard },
  { label: "Profile", href: "/profile", icon: CircleUserRound },
];

export default function AppShell({ children }: AppShellProps) {
  const pathname = usePathname();
  const [mobileOpen, setMobileOpen] = useState(false);
  return <div className="app-frame min-h-screen">
    <aside className={["app-sidebar fixed inset-y-0 left-0 z-50 w-[272px] transition-transform duration-300", mobileOpen ? "translate-x-0" : "-translate-x-full", "lg:translate-x-0"].join(" ")}>
      <div className="flex h-full flex-col">
        <div className="app-brand flex h-[88px] items-center justify-between px-6">
          <Link href="/dashboard" className="flex items-center gap-3" onClick={() => setMobileOpen(false)}>
            <div className="app-brand-mark flex h-11 w-11 items-center justify-center rounded-2xl text-white"><GraduationCap size={23}/></div>
            <div><div className="text-[15px] font-bold tracking-tight">Loyola</div><div className="mt-0.5 text-xs app-muted">Student space</div></div>
          </Link>
          <button onClick={() => setMobileOpen(false)} className="app-icon-button lg:hidden" aria-label="Close navigation"><X size={19}/></button>
        </div>
        <div className="px-5 pb-2 pt-5"><p className="app-eyebrow px-3">YOUR CAMPUS</p></div>
        <nav className="flex-1 space-y-1 px-3 py-2">
          {navigation.map(item => {
            const Icon = item.icon;
            const active = pathname === item.href || pathname.startsWith(item.href + "/");
            return <Link key={item.href} href={item.href} onClick={() => setMobileOpen(false)} aria-current={active ? "page" : undefined} className={["app-nav-link", active ? "app-nav-link-active" : ""].join(" ")}>
              <Icon size={19} strokeWidth={active ? 2.3 : 1.8}/><span>{item.label}</span>{active && <span className="app-nav-indicator"/>}
            </Link>;
          })}
        </nav>
        <div className="p-4">
          <div className="app-sidebar-note rounded-2xl p-4"><div className="text-sm font-semibold">Keep moving forward.</div><p className="mt-1 text-xs leading-5 app-muted">Your classes, progress and campus life in one place.</p></div>
          <div className="mt-4 border-t app-divider pt-3"><Link href="/profile" className="app-nav-link"><LogOut size={18}/><span>Account &amp; settings</span></Link></div>
        </div>
      </div>
    </aside>
    {mobileOpen && <button className="fixed inset-0 z-40 bg-black/45 backdrop-blur-sm lg:hidden" onClick={() => setMobileOpen(false)} aria-label="Close navigation overlay"/>}
    <div className="lg:pl-[272px]">
      <header className="app-topbar sticky top-0 z-30 flex h-[72px] items-center justify-between px-4 sm:px-6 lg:px-10">
        <div className="flex items-center gap-3">
          <button onClick={() => setMobileOpen(true)} className="app-icon-button lg:hidden" aria-label="Open navigation"><Menu size={21}/></button>
          <div><p className="app-eyebrow hidden sm:block">LOYOLA COLLEGE</p><h1 className="text-[15px] font-semibold tracking-tight sm:mt-1">Student portal</h1></div>
        </div>
        <Link href="/profile" className="flex items-center gap-3 rounded-full p-1 transition hover:bg-black/5">
          <div className="hidden text-right sm:block"><div className="text-sm font-semibold">My account</div><div className="text-xs app-muted">Academic profile</div></div>
          <div className="app-avatar flex h-10 w-10 items-center justify-center rounded-full"><CircleUserRound size={20}/></div>
        </Link>
      </header>
      <main className="app-main min-h-[calc(100vh-4.5rem)] px-4 pb-28 pt-6 sm:px-6 sm:pt-8 lg:px-10 lg:pb-10"><div className="mx-auto w-full max-w-[1440px]">{children}</div></main>
    </div>
    <nav className="app-mobile-nav fixed inset-x-0 bottom-0 z-40 lg:hidden" aria-label="Mobile navigation">
      {navigation.filter(item => ["/dashboard", "/attendance", "/subjects", "/marks", "/profile"].includes(item.href)).map(item => {
        const Icon = item.icon; const active = pathname === item.href || pathname.startsWith(item.href + "/");
        return <Link key={item.href} href={item.href} aria-current={active ? "page" : undefined} className={["app-mobile-nav-item", active ? "app-mobile-nav-active" : ""].join(" ")}>
          <span className="app-mobile-icon"><Icon size={20} strokeWidth={active ? 2.4 : 1.8}/></span><span>{item.label}</span>
        </Link>;
      })}
    </nav>
  </div>;
}