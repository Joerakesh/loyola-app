"use client";

import { useEffect, useMemo, useState } from "react";
import { Award, BookOpenCheck, ChartNoAxesColumn, RefreshCw } from "lucide-react";
import AppShell from "@/components/layout/app-shell";
import { getInternalMarks, type InternalMarkRecord } from "@/lib/api/erp";

export default function MarksPage() {
  const [marks, setMarks] = useState<InternalMarkRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [semester, setSemester] = useState("all");

  async function load() {
    try { setLoading(true); setError(""); const response = await getInternalMarks(); setMarks(response.data ?? []); }
    catch (e) { setError(e instanceof Error ? e.message : "Unable to load internal marks."); }
    finally { setLoading(false); }
  }
  useEffect(() => { void load(); }, []);
  const semesters = useMemo(() => Array.from(new Set(marks.map(m => m.semester).filter(Boolean))).sort((a,b) => a-b), [marks]);
  const filtered = marks.filter(m => semester === "all" || String(m.semester) === semester);
  const available = marks.filter(m => m.marksAvailable);
  const average = available.length ? available.reduce((sum,m) => sum + (m.totals?.outOf100 ?? 0), 0) / available.length : null;

  return <AppShell><div className="space-y-7">
    <header className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between"><div><p className="app-kicker">Assessment centre</p><h1 className="app-page-title mt-2">Internal marks</h1><p className="app-muted-text mt-2 max-w-xl text-sm leading-6">Review the marks published by your academic system. Only returned results are shown.</p></div><label className="text-sm"><span className="app-muted-text mb-1.5 block text-xs font-semibold">Filter by semester</span><select className="app-input h-11 min-w-44 px-3 text-sm" value={semester} onChange={e=>setSemester(e.target.value)}><option value="all">All semesters</option>{semesters.map(s=><option key={s} value={String(s)}>Semester {s}</option>)}</select></label></header>
    <section className="grid gap-4 sm:grid-cols-3"><Metric icon={<BookOpenCheck size={19}/>} label="Courses" value={loading?"—":String(marks.length)}/><Metric icon={<Award size={19}/>} label="Marks available" value={loading?"—":String(available.length)}/><Metric icon={<ChartNoAxesColumn size={19}/>} label="Average total / 100" value={loading?"—":average===null?"—":average.toFixed(1)}/></section>
    {loading ? <Loading/> : error ? <div className="app-card p-6"><p className="font-semibold">Marks are temporarily unavailable</p><p className="app-muted-text mt-1 text-sm">{error}</p><button onClick={()=>void load()} className="app-button-primary mt-4 min-h-10 px-4 text-sm"><RefreshCw size={15}/>Retry</button></div> : filtered.length===0 ? <div className="app-empty"><Award size={26} className="mx-auto mb-3 opacity-60"/><p className="font-semibold text-[var(--foreground)]">No marks published</p><p className="mt-1 text-sm">When your ERP publishes internal results, they’ll appear here.</p></div> :
    <div className="space-y-4">{filtered.map((course,i)=><article key={course.courseCode||i} className="app-card overflow-hidden"><div className="flex flex-col gap-3 border-b border-[var(--line)] p-5 sm:flex-row sm:items-start sm:justify-between sm:px-6"><div className="flex gap-3"><span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-[var(--brand-soft)] text-[var(--brand)]"><BookOpenCheck size={19}/></span><div><h2 className="font-semibold leading-5">{course.courseName || "Course"}</h2><p className="app-muted-text mt-1 font-mono text-xs">{course.courseCode || "—"} · Semester {course.semester || "—"}</p><p className="app-muted-text mt-2 text-xs">{course.faculty || "Faculty not listed"}{course.credits ? ` · ${course.credits} credits` : ""}</p></div></div>{course.totals && <div className="rounded-xl bg-[var(--surface-soft)] px-4 py-3 sm:min-w-32 sm:text-right"><p className="app-muted-text text-xs">Final internal total</p><p className="app-stat-value mt-1">{course.totals.final}<span className="app-muted-text text-sm font-medium"> / 50</span></p></div>}</div>
      {!course.marksAvailable || !course.components.length ? <div className="p-5 sm:px-6"><span className="app-pill">Marks not published yet</span></div> : <><div className="grid gap-3 p-4 sm:grid-cols-2 lg:grid-cols-3 sm:p-6">{course.components.map((c,j)=><div key={c.id||j} className="rounded-xl border border-[var(--line)] p-4"><div className="flex items-center justify-between gap-3"><span className="text-sm font-medium">{c.name || "Assessment"}</span><span className="font-semibold tabular-nums">{c.mark===null?"—":c.mark}<span className="app-muted-text text-xs"> / {c.maxMark}</span></span></div>{c.mark!==null && c.maxMark>0 && <div className="mt-3 h-1.5 overflow-hidden rounded-full bg-[var(--surface-soft)]"><div className="h-full rounded-full bg-[var(--brand)]" style={{width:`${Math.min(100,Math.max(0,c.mark/c.maxMark*100))}%`}}/></div>}</div>)}</div>{course.totals && <div className="flex flex-wrap gap-2 border-t border-[var(--line)] px-5 py-4 sm:px-6"><span className="app-pill">Total / 50: {course.totals.outOf50}</span><span className="app-pill">Total / 100: {course.totals.outOf100}</span><span className="app-pill">Attendance mark: {course.totals.attendance}</span></div>}</>}
    </article>)}</div>}
  </div></AppShell>;
}
function Metric({icon,label,value}:{icon:React.ReactNode;label:string;value:string}){return <div className="app-card p-5"><div className="flex items-center justify-between"><span className="app-muted-text text-sm">{label}</span><span className="flex h-9 w-9 items-center justify-center rounded-xl bg-[var(--surface-soft)] text-[var(--brand)]">{icon}</span></div><p className="app-stat-value mt-4">{value}</p></div>}
function Loading(){return <div className="app-card flex min-h-48 items-center justify-center gap-3 app-muted-text"><span className="h-5 w-5 animate-spin rounded-full border-2 border-[var(--line)] border-t-[var(--brand)]"/>Loading internal marks…</div>}
