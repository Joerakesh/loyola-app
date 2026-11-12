"use client";

import { useCallback, useEffect, useState } from "react";
import { BadgeIndianRupee, FileCheck2, ReceiptText, ShieldCheck, RefreshCw } from "lucide-react";
import AppShell from "@/components/layout/app-shell";
import { getPortalSection } from "@/lib/api/erp";

type FeeRow = Record<string, unknown>;
type FeesBundle = Record<string, unknown>;

function readField(value: unknown, field: string): unknown {
 if(!value||typeof value!=="object"||Array.isArray(value))return undefined;
 const match=Object.entries(value).find(([key])=>key.toLowerCase()===field.toLowerCase());
 return match?.[1];
}

function readRows(value: unknown): FeeRow[] {
 if(Array.isArray(value))return value as FeeRow[];
 const nested=readField(value,"data");
 if(Array.isArray(nested))return nested as FeeRow[];
 if(nested&&typeof nested==="object")return readRows(nested);
 return [];
}

function money(value: unknown) {
 const amount=Number(value); return Number.isFinite(amount)?amount.toLocaleString("en-IN",{style:"currency",currency:"INR",maximumFractionDigits:0}):"—";
}

export default function FeesPage(){
 const [fees,setFees]=useState<FeesBundle|null>(null);const [loading,setLoading]=useState(true);const [error,setError]=useState("");
 const load = useCallback(async () => {try{setLoading(true);setError("");const r=await getPortalSection<FeesBundle>("fees");const unavailable=r.unavailable.find(item=>item.section==="fees");if(unavailable||!r.data){throw new Error(unavailable?.message??"The ERP did not return fee data.")}const paymentPayload=readField(r.data,"payments");if(!Array.isArray(paymentPayload)&&readRows(paymentPayload).length===0){throw new Error("The ERP fee response did not contain a payment list.")}setFees(r.data)}catch(e){setFees(null);setError(e instanceof Error?e.message:"Unable to load fee information.")}finally{setLoading(false)}},[]);
 useEffect(()=>{void load()},[load]);
 const payments=readRows(readField(fees,"payments"));
 const totalPaid=payments.length?payments.reduce((sum,payment)=>sum+(Number(readField(payment,"total_amount"))||0),0):Number(readField(fees,"summaryTotalPaid"))||0;
 const dueRows=readRows(readField(fees,"due"));
 return <AppShell><div className="space-y-7">
  <header><p className="app-kicker">Student finance</p><h1 className="app-page-title mt-2">Fees & payments</h1><p className="app-muted-text mt-2 max-w-xl text-sm leading-6">A simple overview of the fee information currently available from your student portal.</p></header>
  {loading?<div className="app-card flex min-h-48 items-center justify-center gap-3 app-muted-text"><span className="h-5 w-5 animate-spin rounded-full border-2 border-[var(--line)] border-t-[var(--brand)]"/>Loading fee information…</div>:error?<div className="app-card p-6"><p className="font-semibold">Fee information unavailable</p><p className="app-muted-text mt-1 text-sm">{error}</p><button onClick={()=>void load()} className="app-button-primary mt-4 min-h-10 px-4 text-sm"><RefreshCw size={15}/>Retry</button></div>:<><section className="grid gap-4 lg:grid-cols-[1.2fr_.8fr]"><div className="relative overflow-hidden rounded-[24px] bg-[var(--brand-deep)] p-7 text-white sm:p-9"><div className="relative z-10"><span className="inline-flex items-center gap-2 text-xs font-semibold text-white/70"><BadgeIndianRupee size={16}/>{payments.length?"Paid total from receipts":"Paid total from LRMS dashboard summary"}</span><p className="mt-5 text-4xl font-bold tracking-tight sm:text-5xl">{money(totalPaid)}</p><p className="mt-3 max-w-md text-sm leading-6 text-white/70">{payments.length?"Total of the payment rows returned by Loyola ERP.":"The ERP returned no itemized receipt rows, so this total uses its dashboard summary."} Outstanding dues are shown separately below.</p></div><div className="pointer-events-none absolute -right-10 -top-16 h-64 w-64 rounded-full border border-white/10 shadow-[0_0_0_32px_rgba(255,255,255,.03),0_0_0_70px_rgba(255,255,255,.025)]"/></div><div className="app-card p-6"><div className="flex h-11 w-11 items-center justify-center rounded-xl bg-[var(--surface-soft)] text-[var(--brand)]"><ShieldCheck size={21}/></div><h2 className="mt-5 font-semibold">Verified source</h2><p className="app-muted-text mt-2 text-sm leading-6">Payment and due information comes from your authenticated Loyola ERP account.</p><p className="app-muted-text mt-3 text-xs">Department: {String(readField(readField(fees,"department"),"department") ?? "Not returned")}</p></div></section>
  <section className="app-card overflow-hidden"><div className="border-b border-[var(--line)] p-5 sm:px-6"><h2 className="app-section-title">Payment history</h2><p className="app-muted-text mt-1 text-sm">{payments.length} payment record{payments.length===1?"":"s"} returned by the ERP.</p></div>{payments.length===0?<p className="app-muted-text p-5 text-sm">No payment records returned.</p>:<div className="overflow-x-auto"><table className="app-table"><thead><tr><th>Date</th><th>Fee</th><th>Term</th><th>Amount</th><th>Status</th><th>Receipt mode</th></tr></thead><tbody>{payments.map((p,i)=><tr key={String(readField(p,"serial_no")??i)}><td>{String(readField(p,"receipt_date")??"—")}</td><td>{String(readField(p,"fee_type")??"Fee")}</td><td>{String(readField(p,"term")??"—")}</td><td className="font-semibold">{money(readField(p,"total_amount"))}</td><td>{String(readField(p,"pay_status")??"—")}</td><td>{String(readField(p,"receipt_mode")??"—")}</td></tr>)}</tbody></table></div>}</section>
  <section className="app-card overflow-hidden"><div className="border-b border-[var(--line)] p-5 sm:px-6"><h2 className="app-section-title">Outstanding fee details</h2></div>{dueRows.length===0?<p className="app-muted-text p-5 text-sm">No outstanding fee rows were returned by the ERP.</p>:<div className="divide-y divide-[var(--line)]">{dueRows.map((p,i)=><div key={String(readField(p,"serial_no")??i)} className="flex flex-wrap items-center justify-between gap-3 p-5"><div><p className="font-medium">{String(readField(p,"fee_type")??readField(p,"term")??"Fee")}</p><p className="app-muted-text mt-1 text-xs">Due from {String(readField(p,"fee_due_starts_from")??"—")}</p></div><p className="font-semibold">{money(readField(p,"due_amount"))}</p></div>)}</div>}</section>
  <section className="grid gap-4 md:grid-cols-3"><StatusCard title="Registration payment" item={readField(fees,"registrationPayments") as Record<string,unknown>|undefined}/><StatusCard title="Condonation payment" item={readField(fees,"condonationPayments") as Record<string,unknown>|undefined}/><StatusCard title="Challan notice" item={readField(fees,"notification") as Record<string,unknown>|undefined}/></section>
  <section className="app-card p-5"><div className="flex items-start gap-4"><div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-[var(--surface-soft)] text-[var(--brand)]"><FileCheck2 size={20}/></div><div><h2 className="app-section-title">Active challans</h2><p className="app-muted-text mt-1 text-sm">{readRows(readField(fees,"activeChallans")).length} active fee challan configuration(s) returned.</p></div></div></section></>}
 </div></AppShell>
}

function StatusCard({title,item}:{title:string;item?:Record<string,unknown>}){return <article className="app-card p-5"><p className="app-muted-text text-xs">{title}</p><p className="mt-2 font-semibold">{String(readField(item,"message")??readField(item,"status")??readField(item,"success")??"No status returned")}</p>{readField(item,"error")!=null&&<p className="app-muted-text mt-1 text-sm">{String(readField(item,"error"))}</p>}</article>}
