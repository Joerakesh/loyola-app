"use client";

import { useState } from "react";
import { signInWithPopup } from "firebase/auth";
import { firebaseAuth, googleProvider } from "@/lib/firebase";
import { loginWithGoogle } from "@/lib/api/auth";
import { useRouter } from "next/navigation";
import { Globe, Loader2 } from "lucide-react";

export default function LoginPage() {
    const router = useRouter();

    const [loading, setLoading] = useState(false);
    const [error, setError] = useState("");

    async function handleGoogleLogin() {
        try {
            setLoading(true);
            setError("");

            const result = await signInWithPopup(
                firebaseAuth,
                googleProvider,
            );

            const idToken = await result.user.getIdToken();

            const user = await loginWithGoogle(idToken);

            if (user.erpLinked) {
                router.replace("/dashboard");
            } else {
                router.replace("/link-erp");
            }
        } catch (error) {
            console.error(error);

            setError(
                "Unable to sign in with Google. Please try again.",
            );
        } finally {
            setLoading(false);
        }
    }

    return (
        <main className="min-h-screen bg-slate-50 flex items-center justify-center p-6">
            <div className="w-full max-w-md">
                <div className="rounded-2xl bg-white border border-slate-200 shadow-sm p-8">
                    <div className="mb-8 text-center">
                        <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-slate-900 text-white">
                            <span className="text-xl font-bold">L</span>
                        </div>

                        <h1 className="text-2xl font-bold text-slate-900">
                            Loyola ERP
                        </h1>

                        <p className="mt-2 text-sm text-slate-500">
                            Sign in to access your student portal
                        </p>
                    </div>

                    <button
                        onClick={handleGoogleLogin}
                        disabled={loading}
                        className="flex w-full items-center justify-center gap-3 rounded-xl border border-slate-300 bg-white px-4 py-3 font-medium text-slate-700 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-60"
                    >
                        {loading ? (
                            <Loader2 className="h-5 w-5 animate-spin" />
                        ) : (
                            <Globe className="h-5 w-5" />
                        )}

                        {loading
                            ? "Signing in..."
                            : "Continue with Google"}
                    </button>

                    {error && (
                        <p className="mt-4 rounded-lg bg-red-50 p-3 text-sm text-red-600">
                            {error}
                        </p>
                    )}

                    <p className="mt-6 text-center text-xs text-slate-400">
                        Your Google account is used to identify your Loyola ERP
                        account.
                    </p>
                </div>
            </div>
        </main>
    );
}