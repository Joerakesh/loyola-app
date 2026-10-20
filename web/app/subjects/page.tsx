"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { BookOpen, Search, Users, Layers3, RefreshCw } from "lucide-react";
import AppShell from "@/components/layout/app-shell";
import { getSubjects, type SubjectRecord } from "@/lib/api/erp";

export default function SubjectsPage() {
  const [subjects, setSubjects] = useState<SubjectRecord[]>([]);
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const load = useCallback(async () => {
    try { setLoading(true); setError(""); const response = await getSubjects(); setSubjects(response.data ?? []); }
    catch (e) { setError(e instanceof Error ? e.message : "Unable to load subjects."); }
    finally { setLoading(false); }
  }, []);
  useEffect(() => { void load(); }, [load]);

  const filtered = useMemo(() => subjects.filter(s => [s.course_title, s.course_code, s.faculty, String(s.semester)].join(" ").toLowerCase().includes(search.toLowerCase())), [subjects, search]);
  const credits = subjects.reduce((sum, s) => sum + (Number(s.credits) || 0), 0);

  return <AppShell>
    <div className="space-y-7">
      <header className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <div><p className="app-kicker">Academic records</p><h1 className="app-page-title mt-2">Your subjects</h1><p className="app-muted-text mt-2 max-w-xl text-sm leading-6">A clear view of your courses, credits and faculty details for the current academic record.</p></div>
        <div className="relative w-full sm:max-w-xs"><Search size={17} className="app-muted-text absolute left-3.5 top-1/2 -translate-y-1/2"/><input aria-label="Search subjects" className="app-input h-11 pl-10 pr-4 text-sm" placeholder="Search subjects or faculty" value={search} onChange={e => setSearch(e.target.value)}/></div>
      </header>
      <section className="grid gap-4 sm:grid-cols-3">
        <Metric icon={<BookOpen size={19}/>} label="Courses" value={loading ? "—" : String(subjects.length)} />
        <Metric icon={<Layers3 size={19}/>} label="Total credits" value={loading ? "—" : String(credits)} />
        <Metric icon={<Users size={19}/>} label="Faculty listed" value={loading ? "—" : String(new Set(subjects.map(s => s.faculty).filter(Boolean)).size)} />
      </section>
      {loading ? <LoadingState label="Loading your subjects…" /> : error ? <ErrorState message={error} retry={() => void load()} /> : filtered.length === 0 ? <div className="app-empty"><BookOpen size={26} className="mx-auto mb-3 opacity-60"/><p className="font-semibold text-[var(--foreground)]">{search ? "No matching subjects" : "No subject records yet"}</p><p className="mt-1 text-sm">{search ? "Try another course name, code or faculty member." : "Subject records will appear here when the academic system returns them."}</p></div> :
        <section className="app-card overflow-hidden">
          <div className="flex items-center justify-between border-b border-[var(--line)] px-5 py-4 sm:px-6"><div><h2 className="app-section-title">Course directory</h2><p className="app-muted-text mt-1 text-xs">{filtered.length} course{filtered.length === 1 ? "" : "s"} shown</p></div><span className="app-pill">Live ERP data</span></div>
          <div className="hidden overflow-x-auto md:block"><table className="app-table"><thead><tr><th>Course</th><th>Code</th><th>Semester</th><th>Credits</th><th>Faculty</th></tr></thead><tbody>{filtered.map((s, i) => <tr key={s.course_code || i}><td><div className="font-semibold">{s.course_title || "Untitled course"}</div></td><td><span className="font-mono text-xs app-muted-text">{s.course_code || "—"}</span></td><td><span className="app-pill">Semester {s.semester || "—"}</span></td><td className="font-semibold">{s.credits ?? "—"}</td><td className="app-muted-text">{s.faculty || "Not listed"}</td></tr>)}</tbody></table></div>
          <div className="divide-y divide-[var(--line)] md:hidden">{filtered.map((s, i) => <article key={s.course_code || i} className="p-4"><div className="flex items-start gap-3"><div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-[var(--brand-soft)] text-[var(--brand)]"><BookOpen size={18}/></div><div className="min-w-0 flex-1"><h3 className="font-semibold leading-5">{s.course_title || "Untitled course"}</h3><p className="app-muted-text mt-1 font-mono text-xs">{s.course_code || "No course code"}</p><p className="app-muted-text mt-3 text-xs">{s.faculty || "Faculty not listed"}</p><div className="mt-3 flex flex-wrap gap-2"><span className="app-pill">Semester {s.semester || "—"}</span><span className="app-pill">{s.credits ?? "—"} credits</span></div></div></div></article>)}</div>
        </section>}
    </div>
  </AppShell>;
}

function Metric({icon,label,value}:{icon:React.ReactNode;label:string;value:string}) { return <div className="app-card p-5"><div className="flex items-center justify-between"><span className="app-muted-text text-sm">{label}</span><span className="flex h-9 w-9 items-center justify-center rounded-xl bg-[var(--surface-soft)] text-[var(--brand)]">{icon}</span></div><p className="app-stat-value mt-4">{value}</p></div>; }
function LoadingState({label}:{label:string}) { return <div className="app-card flex min-h-48 items-center justify-center gap-3 p-8 app-muted-text"><span className="h-5 w-5 animate-spin rounded-full border-2 border-[var(--line)] border-t-[var(--brand)]"/>{label}</div>; }
function ErrorState({message,retry}:{message:string;retry:()=>void}) { return <div className="app-card p-6"><p className="font-semibold">We couldn’t load this page</p><p className="app-muted-text mt-1 text-sm">{message}</p><button onClick={retry} className="app-button-primary mt-4 min-h-10 px-4 text-sm"><RefreshCw size={15}/>Try again</button></div>; }
