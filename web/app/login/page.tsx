"use client";
import { useEffect, useState } from "react";
import { signInWithPopup } from "firebase/auth";
import { firebaseAuth, googleProvider } from "@/lib/firebase";
import { loginWithGoogle } from "@/lib/api/auth";
import { useRouter } from "next/navigation";
import { ArrowRight, GraduationCap, Loader2, ShieldCheck, Moon, Sun } from "lucide-react";

export default function LoginPage() {
 const router=useRouter(); const [loading,setLoading]=useState(false); const [error,setError]=useState(""); const [theme,setTheme]=useState<"light"|"dark">("light");
 useEffect(()=>{const saved=window.localStorage.getItem("loyola.theme");const next=saved==="dark"||saved==="light"?saved:window.matchMedia("(prefers-color-scheme: dark)").matches?"dark":"light";document.documentElement.dataset.theme=next;setTheme(next)},[]);
 function toggleTheme(){const next=theme==="dark"?"light":"dark";document.documentElement.dataset.theme=next;window.localStorage.setItem("loyola.theme",next);setTheme(next)}
 async function handleGoogleLogin(){try{setLoading(true);setError("");const result=await signInWithPopup(firebaseAuth,googleProvider);const idToken=await result.user.getIdToken();const user=await loginWithGoogle(idToken);router.replace(user.erpLinked?"/dashboard":"/link-erp")}catch(error){console.error(error);setError("Unable to sign in with Google. Please try again.")}finally{setLoading(false)}}
 return <main className="login-page relative flex min-h-screen items-center justify-center overflow-hidden px-5 py-12">
  <button type="button" onClick={toggleTheme} className="app-icon-button fixed right-5 top-5 z-20" aria-label={theme==="dark"?"Switch to light theme":"Switch to dark theme"} title={theme==="dark"?"Light theme":"Dark theme"}>{theme==="dark"?<Sun size={18}/>:<Moon size={18}/>}</button>
  <div className="login-orb login-orb-one"/><div className="login-orb login-orb-two"/>
  <div className="relative z-10 grid w-full max-w-5xl overflow-hidden rounded-[30px] border border-white/70 bg-white shadow-[0_28px_100px_rgba(55,35,25,.12)] md:grid-cols-[1.05fr_.95fr]">
   <section className="login-story relative hidden min-h-[590px] flex-col justify-between overflow-hidden p-10 text-white md:flex lg:p-14">
    <div className="relative z-10 flex items-center gap-3"><div className="flex h-12 w-12 items-center justify-center rounded-2xl border border-white/20 bg-white/10"><GraduationCap size={26}/></div><div><p className="text-sm font-bold tracking-wide">LOYOLA COLLEGE</p><p className="mt-1 text-xs text-white/60">Student portal</p></div></div>
    <div className="relative z-10 max-w-sm"><p className="mb-4 text-xs font-bold uppercase tracking-[.2em] text-white/60">Your campus, connected</p><h1 className="text-4xl font-semibold leading-[1.12] tracking-tight lg:text-5xl">Your academic life, <span className="text-[#d9f06a]">in one place.</span></h1><p className="mt-5 max-w-xs text-sm leading-7 text-white/70">Attendance, results, timetable and essential student services—together in one simple space.</p><div className="mt-9 flex items-center gap-3 text-sm text-white/80"><span className="flex h-9 w-9 items-center justify-center rounded-full bg-white/10"><ShieldCheck size={17}/></span>Built around your Loyola student experience</div></div>
    <div className="relative z-10 flex items-center justify-between text-xs text-white/50"><span>Learn · Grow · Belong</span><span>Chennai, India</span></div><div className="login-decoration"/>
   </section>
   <section className="flex flex-col justify-center px-6 py-10 sm:px-10 md:px-10 lg:px-14">
    <div className="mb-9 flex items-center gap-3 md:hidden"><div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-[#8b0000] text-white"><GraduationCap size={24}/></div><div><p className="font-bold">Loyola College</p><p className="mt-0.5 text-xs text-stone-500">Student portal</p></div></div>
    <p className="text-xs font-bold uppercase tracking-[.18em] text-[#8b0000]">Welcome back</p><h2 className="mt-3 text-3xl font-semibold tracking-tight text-[#24221f]">Sign in to continue.</h2><p className="mt-3 text-sm leading-6 text-stone-500">Use your Google account to securely access your academic dashboard.</p>
    <button onClick={handleGoogleLogin} disabled={loading} className="app-button-primary mt-8 min-h-[54px] w-full px-5 text-sm disabled:cursor-not-allowed disabled:opacity-60">{loading?<Loader2 className="h-5 w-5 animate-spin"/>:<span className="flex h-6 w-6 items-center justify-center rounded-full bg-white text-sm font-bold text-[#4285F4]">G</span>}{loading?"Signing in...":"Continue with Google"}{!loading&&<ArrowRight size={17} className="ml-auto"/>}</button>
    {error&&<p role="alert" className="mt-4 rounded-xl border border-red-100 bg-red-50 p-3 text-sm text-red-700">{error}</p>}
    <div className="my-7 flex items-center gap-3 text-xs text-stone-400"><span className="h-px flex-1 bg-stone-200"/><span>SECURE STUDENT ACCESS</span><span className="h-px flex-1 bg-stone-200"/></div>
    <div className="flex gap-3 rounded-2xl bg-[#f7f5f1] p-4"><ShieldCheck className="mt-0.5 shrink-0 text-[#8b0000]" size={19}/><p className="text-xs leading-5 text-stone-500">Your Google account identifies your Loyola ERP profile. Your password is never requested or stored by this page.</p></div>
    <p className="mt-8 text-center text-xs text-stone-400">By continuing, you agree to use the student portal responsibly.</p>
   </section>
  </div>
 </main>;
}