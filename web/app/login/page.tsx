"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { signInWithPopup } from "firebase/auth";
import { ArrowRight, Loader2, Moon, ShieldCheck, Sun } from "lucide-react";
import { firebaseAuth, googleProvider } from "@/lib/firebase";
import { loginWithGoogle } from "@/lib/api/auth";
import { BRAND, CHURCH_ALT, CHURCH_IMAGE } from "@/lib/brand";
import IhsMark from "@/components/brand/ihs-mark";

export default function LoginPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [theme, setTheme] = useState<"light" | "dark">("light");

  useEffect(() => {
    const saved = window.localStorage.getItem("loyola.theme");
    const next =
      saved === "dark" || saved === "light"
        ? saved
        : window.matchMedia("(prefers-color-scheme: dark)").matches
          ? "dark"
          : "light";
    document.documentElement.dataset.theme = next;
    setTheme(next);
  }, []);

  function toggleTheme() {
    const next = theme === "dark" ? "light" : "dark";
    document.documentElement.dataset.theme = next;
    window.localStorage.setItem("loyola.theme", next);
    setTheme(next);
  }

  async function handleGoogleLogin() {
    try {
      setLoading(true);
      setError("");
      const result = await signInWithPopup(firebaseAuth, googleProvider);
      const idToken = await result.user.getIdToken();
      const user = await loginWithGoogle(idToken);
      router.replace(user.erpLinked ? "/dashboard" : "/link-erp");
    } catch (caught) {
      console.error(caught);
      setError("Google sign-in did not complete. Check that pop-ups are allowed, then try again.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="login-page relative flex min-h-screen items-center justify-center px-4 py-10 sm:px-6">
      <button
        type="button"
        onClick={toggleTheme}
        className="app-icon-button fixed right-4 top-4 z-20"
        aria-label={theme === "dark" ? "Switch to light theme" : "Switch to dark theme"}
        title={theme === "dark" ? "Light theme" : "Dark theme"}
      >
        {theme === "dark" ? <Sun size={18} /> : <Moon size={18} />}
      </button>

      <div className="login-card grid w-full max-w-5xl overflow-hidden rounded-[18px] md:grid-cols-[1.05fr_.95fr]">
        {/* Story panel: the church in its arch window, with the Jesuit motto */}
        <section className="login-story relative hidden min-h-[600px] flex-col items-center justify-between px-10 pt-9 md:flex">
          <div className="flex w-full items-center gap-3">
            <IhsMark size={46} className="text-white" />
            <div>
              <p className="font-display text-lg leading-5" style={{ fontFamily: "var(--font-display)" }}>
                {BRAND.name}
              </p>
              <p className="mt-0.5 text-xs text-white/65">{BRAND.product}</p>
            </div>
          </div>

          <div className="mt-8 w-full max-w-[300px] flex-1">
            <div className="login-arch-frame h-full">
              <figure className="login-arch h-full min-h-[330px]">
                {/* Plain <img>: an SVG illustration (or your own photo) needs no optimisation */}
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={CHURCH_IMAGE} alt={CHURCH_ALT} />
              </figure>
            </div>
          </div>

          <div className="w-full pb-8 pt-6 text-center">
            <p className="login-motto text-[1.6rem] leading-8">{BRAND.motto}</p>
            <p className="mt-1 text-xs text-white/60">{BRAND.mottoMeaning}</p>
          </div>
        </section>

        {/* Sign-in panel */}
        <section className="flex flex-col justify-center px-6 py-10 sm:px-10 lg:px-14">
          <div className="mb-8 flex items-center gap-3 md:hidden">
            <span className="app-brand-mark flex h-12 w-12 items-center justify-center rounded-xl">
              <IhsMark size={34} className="text-white" />
            </span>
            <div>
              <p className="app-section-title leading-5">{BRAND.name}</p>
              <p className="app-muted-text mt-0.5 text-xs">{BRAND.product}</p>
            </div>
          </div>

          <h1 className="app-page-title">Sign in to your portal</h1>
          <p className="app-muted-text mt-3 max-w-sm text-[15px] leading-7">
            Use your Google account to see your attendance, marks and timetable.
          </p>

          <button
            onClick={handleGoogleLogin}
            disabled={loading}
            className="app-button-primary mt-8 min-h-[54px] w-full px-5 text-sm disabled:cursor-not-allowed disabled:opacity-60"
          >
            {loading ? (
              <Loader2 className="h-5 w-5 animate-spin" />
            ) : (
              <span className="flex h-6 w-6 items-center justify-center rounded-full bg-white text-sm font-bold text-[#4285F4]">
                G
              </span>
            )}
            {loading ? "Signing in…" : "Continue with Google"}
            {!loading && <ArrowRight size={17} className="ml-auto" />}
          </button>

          {error && (
            <p
              role="alert"
              className="mt-4 rounded-[10px] border border-[var(--danger)]/30 bg-[var(--danger)]/10 p-3 text-sm text-[var(--danger)]"
            >
              {error}
            </p>
          )}

          <div className="mt-8 flex gap-3 rounded-[10px] bg-[var(--surface-soft)] p-4">
            <ShieldCheck className="mt-0.5 shrink-0 text-[var(--brand)]" size={19} />
            <p className="app-muted-text text-xs leading-5">
              Google only confirms who you are. After signing in you link your ERP account once, and
              the portal reads your records from it on your behalf.
            </p>
          </div>

          {/* Compact church window for phones, where the story panel is hidden */}
          <div className="mt-9 flex items-end justify-between gap-4 md:hidden">
            <div className="login-arch-frame w-[86px] shrink-0">
              <figure className="login-arch h-[104px]">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={CHURCH_IMAGE} alt="" aria-hidden="true" />
              </figure>
            </div>
            <div className="pb-1 text-right">
              <p className="login-motto text-lg leading-6" style={{ color: "var(--brand)" }}>
                {BRAND.motto}
              </p>
              <p className="app-muted-text text-xs">{BRAND.mottoMeaning}</p>
            </div>
          </div>
        </section>
      </div>
    </main>
  );
}
