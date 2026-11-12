"use client";

import { useCallback, useEffect, useState } from "react";
import { UserRound, Phone, GraduationCap, Building2, BadgeCheck, RefreshCw, Fingerprint } from "lucide-react";
import AppShell from "@/components/layout/app-shell";
import { getPortalSection } from "@/lib/api/erp";

type LrmsProfile = Record<string, string | number | boolean | null | undefined>;

export default function ProfilePage(){
 const [profile,setProfile]=useState<LrmsProfile|null>(null);const [loading,setLoading]=useState(true);const [error,setError]=useState("");
 const load = useCallback(async () => {try{setLoading(true);setError("");const r=await getPortalSection<{profile:{data:LrmsProfile}}>("profile");if(!r.data)throw new Error(r.unavailable.find(item=>item.section==="profile")?.message ?? "No profile data returned by the v2 API.");setProfile(r.data.profile?.data ?? null)}catch(e){setError(e instanceof Error?e.message:"Unable to load your profile.")}finally{setLoading(false)}},[]);
 useEffect(()=>{void load()},[load]);
 const field=(...names:string[])=>{for(const name of names){const value=profile?.[name];if(value!==null&&value!==undefined&&String(value).trim())return String(value)}return ""};
 const name=field("studentname","studentnameinlocal","tamil_name");
 const initials=name.split(/\s+/).filter(Boolean).slice(0,2).map(p=>p[0]).join("").toUpperCase()||"LC";
 return <AppShell><div className="space-y-7">
  <header><p className="app-kicker">Your account</p><h1 className="app-page-title mt-2">Student profile</h1><p className="app-muted-text mt-2 text-sm leading-6">Your academic identity as returned by the Loyola ERP.</p></header>
  {loading?<div className="app-card flex min-h-48 items-center justify-center gap-3 app-muted-text"><span className="h-5 w-5 animate-spin rounded-full border-2 border-[var(--line)] border-t-[var(--brand)]"/>Loading student profile…</div>:error?<div className="app-card p-6"><p className="font-semibold">Profile unavailable</p><p className="app-muted-text mt-1 text-sm">{error}</p><button onClick={()=>void load()} className="app-button-primary mt-4 min-h-10 px-4 text-sm"><RefreshCw size={15}/>Try again</button></div>:!profile?<div className="app-empty"><UserRound size={28} className="mx-auto mb-3 opacity-60"/><p className="font-semibold text-[var(--foreground)]">No profile returned</p><p className="mt-1 text-sm">The ERP did not return a student profile for this account.</p></div>:<>
   <section className="app-card overflow-hidden"><div className="h-2 bg-[var(--brand)]"/><div className="flex flex-col gap-5 p-6 sm:flex-row sm:items-center sm:p-8"><div className="flex h-20 w-20 shrink-0 items-center justify-center rounded-[24px] bg-[var(--brand-soft)] text-2xl font-bold text-[var(--brand)]">{initials}</div><div className="min-w-0 flex-1"><div className="flex flex-wrap items-center gap-2"><h2 className="text-2xl font-bold tracking-tight">{name||"Student"}</h2><span className="app-pill"><BadgeCheck size={13}/>ERP profile</span></div><p className="app-muted-text mt-2 text-sm">{field("registerno","universityregisterno")||"Registration number not listed"}</p><p className="app-muted-text mt-1 text-sm">{field("program_name","course_name")||"Programme not listed"}</p></div><div className="rounded-2xl bg-[var(--surface-soft)] px-4 py-3"><p className="app-muted-text text-xs">Academic year</p><p className="mt-1 font-semibold">{field("academicyear")||"—"}</p></div></div></section>
   <section><div className="mb-4"><h2 className="app-section-title">Personal & academic details</h2><p className="app-muted-text mt-1 text-sm">Information from your linked ERP record.</p></div><div className="grid gap-4 md:grid-cols-2">
    {Object.entries(profile).map(([key,value])=>value!==null&&value!==undefined&&String(value).trim()?<Info key={key} icon={key.includes("mobile")||key.includes("email")?<Phone size={18}/>:key.includes("course")||key.includes("program")||key==="section"?<GraduationCap size={18}/>:key.includes("id")||key.includes("register")?<Fingerprint size={18}/>:<UserRound size={18}/>} label={key.replace(/([A-Z])/g," $1").replaceAll("_"," ").replace(/\b\w/g,(c)=>c.toUpperCase())} value={String(value)}/>:null)}
   </div></section>
   <p className="app-muted-text text-xs leading-5">These read-only fields come directly from your authenticated Loyola ERP profile.</p>
  </>}
 </div></AppShell>
}
function Info({icon,label,value}:{icon:React.ReactNode;label:string;value?:string|null}){return <div className="app-card flex items-start gap-3 p-5"><span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-[var(--surface-soft)] text-[var(--brand)]">{icon}</span><div className="min-w-0"><p className="app-muted-text text-xs font-semibold">{label}</p><p className="mt-1 break-words text-sm font-semibold">{value||"Not provided by ERP"}</p></div></div>}
