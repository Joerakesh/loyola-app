"use client";

import { FormEvent, useState } from "react";
import { CheckCircle2, KeyRound, Loader2 } from "lucide-react";
import AppShell from "@/components/layout/app-shell";
import { changePortalPassword, syncPortalCredential } from "@/lib/api/erp";

export default function SettingsPage() {
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState(false);
  const [currentPassword, setCurrentPassword] = useState("");
  const [nextPassword, setNextPassword] = useState("");
  const [nextConfirmation, setNextConfirmation] = useState("");
  const [changing, setChanging] = useState(false);
  const [changeError, setChangeError] = useState("");
  const [changeSuccess, setChangeSuccess] = useState(false);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError("");
    setSuccess(false);

    if (!password) {
      setError("Enter your new ERP password.");
      return;
    }
    if (password !== confirmPassword) {
      setError("The passwords do not match.");
      return;
    }

    try {
      setSaving(true);
      await syncPortalCredential(password);
      setPassword("");
      setConfirmPassword("");
      setSuccess(true);
    } catch (cause) {
      console.error("[Settings] Failed to update ERP password", cause);
      setError(cause instanceof Error ? cause.message : "Unable to update ERP password.");
    } finally {
      setSaving(false);
    }
  }

  async function handleChangePassword(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setChangeError("");
    setChangeSuccess(false);
    if (!currentPassword || !nextPassword) {
      setChangeError("Enter your current and new ERP passwords.");
      return;
    }
    if (nextPassword !== nextConfirmation) {
      setChangeError("The new passwords do not match.");
      return;
    }
    try {
      setChanging(true);
      await changePortalPassword(currentPassword, nextPassword);
      setCurrentPassword("");
      setNextPassword("");
      setNextConfirmation("");
      setChangeSuccess(true);
    } catch (cause) {
      console.error("[Settings] Failed to change ERP password", cause);
      setChangeError(cause instanceof Error ? cause.message : "Unable to change ERP password.");
    } finally {
      setChanging(false);
    }
  }

  return (
    <AppShell>
      <div className="mx-auto max-w-2xl space-y-6">
        <header>
          <p className="app-muted-text text-sm">Account preferences</p>
          <h1 className="app-page-title mt-1">Settings</h1>
          <p className="app-muted-text mt-2 text-sm">Manage the credentials used to connect your Loyola ERP account.</p>
        </header>

        <section className="app-card p-6 sm:p-8">
          <div className="flex items-start gap-4">
            <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-[var(--surface-soft)] text-[var(--brand)]">
              <KeyRound size={21} />
            </div>
            <div>
              <h2 className="app-section-title">Sync an ERP password you already changed</h2>
              <p className="app-muted-text mt-1 text-sm leading-6">If you changed your password on the official Loyola ERP site, enter it here. We’ll verify it and update the password saved for portal data requests.</p>
            </div>
          </div>

          <form onSubmit={handleSubmit} className="mt-6 space-y-4">
            <div>
              <label htmlFor="new-password" className="mb-2 block text-sm font-medium">New ERP password</label>
              <input id="new-password" type="password" autoComplete="new-password" required value={password} onChange={(event) => setPassword(event.target.value)} className="app-input w-full" />
            </div>
            <div>
              <label htmlFor="confirm-password" className="mb-2 block text-sm font-medium">Confirm new password</label>
              <input id="confirm-password" type="password" autoComplete="new-password" required value={confirmPassword} onChange={(event) => setConfirmPassword(event.target.value)} className="app-input w-full" />
            </div>

            {error && <p role="alert" className="rounded-xl bg-red-50 p-3 text-sm text-red-700">{error}</p>}
            {success && <p role="status" className="flex items-center gap-2 rounded-xl bg-emerald-50 p-3 text-sm text-emerald-700"><CheckCircle2 size={17} />ERP password updated. Your saved connection is ready to use.</p>}

            <button type="submit" disabled={saving} className="app-button-primary min-h-11 px-5 text-sm disabled:cursor-not-allowed disabled:opacity-60">
              {saving && <Loader2 size={16} className="animate-spin" />}
              {saving ? "Verifying password…" : "Sync saved password"}
            </button>
          </form>
        </section>

        <section className="app-card p-6 sm:p-8">
          <div className="flex items-start gap-4"><div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-[var(--surface-soft)] text-[var(--brand)]"><KeyRound size={21}/></div><div><h2 className="app-section-title">Change password from the portal</h2><p className="app-muted-text mt-1 text-sm leading-6">This sends the current and new passwords to Loyola ERP through its password-change request. The saved credential is updated after ERP confirms success.</p></div></div>
          <form onSubmit={handleChangePassword} className="mt-6 space-y-4">
            <div><label htmlFor="current-password" className="mb-2 block text-sm font-medium">Current ERP password</label><input id="current-password" type="password" autoComplete="current-password" required value={currentPassword} onChange={event=>setCurrentPassword(event.target.value)} className="app-input w-full"/></div>
            <div><label htmlFor="portal-new-password" className="mb-2 block text-sm font-medium">New ERP password</label><input id="portal-new-password" type="password" autoComplete="new-password" required value={nextPassword} onChange={event=>setNextPassword(event.target.value)} className="app-input w-full"/></div>
            <div><label htmlFor="portal-confirm-password" className="mb-2 block text-sm font-medium">Confirm new password</label><input id="portal-confirm-password" type="password" autoComplete="new-password" required value={nextConfirmation} onChange={event=>setNextConfirmation(event.target.value)} className="app-input w-full"/></div>
            {changeError&&<p role="alert" className="rounded-xl bg-red-50 p-3 text-sm text-red-700">{changeError}</p>}
            {changeSuccess&&<p role="status" className="flex items-center gap-2 rounded-xl bg-emerald-50 p-3 text-sm text-emerald-700"><CheckCircle2 size={17}/>Loyola ERP password changed and saved.</p>}
            <button type="submit" disabled={changing} className="app-button-primary min-h-11 px-5 text-sm disabled:cursor-not-allowed disabled:opacity-60">{changing&&<Loader2 size={16} className="animate-spin"/>}{changing?"Changing password…":"Change password"}</button>
          </form>
        </section>
      </div>
    </AppShell>
  );
}
