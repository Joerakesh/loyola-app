import Link from "next/link";
import { ArrowRight, Activity, BookOpen, CalendarDays, GraduationCap, ShieldCheck, Sparkles } from "lucide-react";

const features = [
 {icon:Activity,title:"Attendance, at a glance",description:"Keep track of your classes and understand your attendance progress."},
 {icon:BookOpen,title:"Your learning space",description:"Find subjects, academic records and the information you need for class."},
 {icon:CalendarDays,title:"Stay in sync",description:"Check your timetable and keep your academic routine close at hand."},
];
export default function HomePage(){
 return <main className="min-h-screen overflow-hidden bg-[#f6f5f2] text-[#20201f]">
  <header className="sticky top-0 z-30 border-b border-[#e9e6e0]/80 bg-[#f6f5f2]/90 backdrop-blur-xl">
   <div className="mx-auto flex h-[72px] max-w-7xl items-center justify-between px-5 sm:px-8">
    <Link href="/" className="flex items-center gap-3"><span className="flex h-10 w-10 items-center justify-center rounded-2xl bg-[#8b0000] text-white"><GraduationCap size={23}/></span><span><span className="block text-sm font-bold tracking-tight">Loyola College</span><span className="mt-0.5 block text-[11px] text-stone-500">Student space</span></span></Link>
    <div className="flex items-center gap-3"><Link href="/policy" className="hidden rounded-xl px-3 py-2 text-sm font-medium text-stone-600 transition hover:bg-white sm:block">Privacy</Link><Link href="/login" className="app-button-primary px-4 py-2.5 text-sm">Sign in <ArrowRight size={16}/></Link></div>
   </div>
  </header>
  <section className="relative px-5 pb-16 pt-14 sm:px-8 sm:pb-24 sm:pt-20 lg:pt-24">
   <div className="pointer-events-none absolute -right-32 top-4 h-96 w-96 rounded-full bg-[#d9f06a]/25 blur-3xl"/>
   <div className="relative mx-auto grid max-w-7xl items-center gap-14 lg:grid-cols-[1fr_.88fr]">
    <div>
     <div className="mb-7 inline-flex items-center gap-2 rounded-full border border-[#e4dfd5] bg-white/80 px-3.5 py-2 text-xs font-semibold text-stone-600"><Sparkles size={14} className="text-[#8b0000}"/> Your campus, connected</div>
     <h1 className="max-w-2xl text-4xl font-semibold leading-[1.08] tracking-[-.045em] sm:text-6xl lg:text-[68px]">Make space for <span className="text-[#8b0000]">what matters.</span></h1>
     <p className="mt-6 max-w-xl text-base leading-7 text-stone-600 sm:text-lg sm:leading-8">Your academic essentials, brought together in one clear, personal student portal—from attendance and marks to subjects and your timetable.</p>
     <div className="mt-9 flex flex-col gap-3 sm:flex-row"><Link href="/login" className="app-button-primary min-h-12 px-6 text-sm">Open student portal <ArrowRight size={17}/></Link><Link href="/policy" className="inline-flex min-h-12 items-center justify-center rounded-2xl border border-[#ded9d0] bg-white px-5 text-sm font-semibold text-stone-700 transition hover:bg-stone-50">Privacy &amp; policies</Link></div>
     <div className="mt-9 flex items-center gap-3 text-xs text-stone-500"><ShieldCheck size={17} className="text-[#8b0000}"/> Secure access to your student account</div>
    </div>
    <div className="relative mx-auto w-full max-w-[490px]">
     <div className="absolute -inset-4 rounded-[36px] bg-[#e7e3d9] rotate-[-3deg]"/>
     <div className="relative rounded-[30px] border border-white bg-white p-5 shadow-[0_28px_90px_rgba(54,42,25,.12)] sm:p-7">
      <div className="flex items-center justify-between"><div><p className="text-xs font-semibold uppercase tracking-[.14em] text-stone-400">Student overview</p><p className="mt-2 text-xl font-semibold tracking-tight">A little more clarity.</p></div><div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-[#f7e9e8] text-[#8b0000]"><GraduationCap size={22}/></div></div>
      <div className="mt-6 rounded-2xl bg-[#8b0000] p-5 text-white"><div className="flex items-center justify-between text-sm text-white/75"><span>Academic progress</span><Activity size={17}/></div><div className="mt-5 text-4xl font-semibold tracking-tight">Your journey</div><p className="mt-2 text-sm text-white/70">One place for the things that move you forward.</p><div className="mt-5 h-1.5 overflow-hidden rounded-full bg-white/20"><div className="h-full w-3/4 rounded-full bg-[#d9f06a]"/></div></div>
      <div className="mt-4 grid grid-cols-2 gap-3"><div className="rounded-2xl bg-[#f6f5f2] p-4"><span className="flex h-9 w-9 items-center justify-center rounded-xl bg-white text-[#8b0000]"><CalendarDays size={18}/></span><p className="mt-4 text-sm font-semibold">Attendance</p><p className="mt-1 text-xs text-stone-500">Daily overview</p></div><div className="rounded-2xl bg-[#f6f5f2] p-4"><span className="flex h-9 w-9 items-center justify-center rounded-xl bg-white text-[#8b0000]"><BookOpen size={18}/></span><p className="mt-4 text-sm font-semibold">Subjects</p><p className="mt-1 text-xs text-stone-500">Your curriculum</p></div></div>
      <p className="mt-5 text-center text-[11px] text-stone-400">A simpler way to stay close to campus life</p>
     </div>
    </div>
   </div>
  </section>
  <section className="border-t border-[#e9e6e0] bg-white px-5 py-16 sm:px-8 sm:py-20">
   <div className="mx-auto max-w-7xl"><div className="max-w-xl"><p className="text-xs font-bold uppercase tracking-[.16em] text-[#8b0000]">Made for your day</p><h2 className="mt-3 text-3xl font-semibold tracking-tight sm:text-4xl">The essentials, without the clutter.</h2><p className="mt-4 text-sm leading-7 text-stone-500">Designed to feel at home on your phone, with the same tools ready on a larger screen.</p></div>
    <div className="mt-9 grid gap-4 md:grid-cols-3">{features.map(({icon:Icon,title,description},i)=><article key={title} className="app-card app-card-hover p-6 sm:p-7"><div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-[#f7e9e8] text-[#8b0000]"><Icon size={21}/></div><p className="mt-7 text-xs font-bold tracking-widest text-stone-400">0{i+1}</p><h3 className="mt-2 text-lg font-semibold tracking-tight">{title}</h3><p className="mt-2 text-sm leading-6 text-stone-500">{description}</p></article>)}</div>
   </div>
  </section>
  <footer className="border-t border-[#e9e6e0] px-5 py-7 sm:px-8"><div className="mx-auto flex max-w-7xl flex-col gap-3 text-xs text-stone-500 sm:flex-row sm:items-center sm:justify-between"><span>© {new Date().getFullYear()} Loyola student portal</span><div className="flex gap-5"><Link href="/policy" className="hover:text-[#8b0000]">Privacy policy</Link><Link href="/policy" className="hover:text-[#8b0000]">Terms of service</Link></div></div></footer>
 </main>;
}