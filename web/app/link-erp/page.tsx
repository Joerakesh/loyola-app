"use client";

import { FormEvent, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Link, Loader2 } from "lucide-react";

import {
    bindErp,
    getCurrentUser,
    User,
} from "@/lib/api/auth";

export default function LinkErpPage() {
    const router = useRouter();

    const [user, setUser] = useState<User | null>(null);

    const [registrationNumber, setRegistrationNumber] =
        useState("");

    const [password, setPassword] = useState("");

    const [email, setEmail] = useState("");

    const [loading, setLoading] = useState(true);
    const [submitting, setSubmitting] = useState(false);
    const [error, setError] = useState("");

    useEffect(() => {
        async function loadUser() {
            try {
                const currentUser = await getCurrentUser();

                setUser(currentUser);

                if (currentUser.erpLinked) {
                    router.replace("/dashboard");
                    return;
                }

                setEmail(currentUser.email ?? "");
            } catch {
                router.replace("/login");
            } finally {
                setLoading(false);
            }
        }

        loadUser();
    }, [router]);

    async function handleSubmit(
        event: FormEvent<HTMLFormElement>,
    ) {
        event.preventDefault();

        setError("");

        if (!registrationNumber.trim()) {
            setError("Enter your registration number.");
            return;
        }

        if (!password) {
            setError("Enter your ERP password.");
            return;
        }

        try {
            setSubmitting(true);

            await bindErp(
                registrationNumber.trim(),
                password,
                email.trim() || undefined,
            );

            router.replace("/dashboard");
        } catch (error: any) {
            console.error(error);

            setError(
                error?.message ??
                "Unable to link your ERP account.",
            );
        } finally {
            setSubmitting(false);
        }
    }

    if (loading) {
        return (
            <main className="min-h-screen flex items-center justify-center">
                <Loader2 className="h-6 w-6 animate-spin text-slate-500" />
            </main>
        );
    }

    return (
        <main className="min-h-screen bg-slate-50 flex items-center justify-center p-6">
            <div className="w-full max-w-md">
                <div className="rounded-2xl bg-white border border-slate-200 shadow-sm p-8">
                    <div className="mb-7">
                        <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-xl bg-slate-900 text-white">
                            <Link className="h-5 w-5" />
                        </div>

                        <h1 className="text-2xl font-bold text-slate-900">
                            Link your ERP
                        </h1>

                        <p className="mt-2 text-sm leading-6 text-slate-500">
                            Connect your Loyola ERP account to continue.
                        </p>
                    </div>

                    {user && (
                        <div className="mb-6 rounded-xl bg-slate-50 p-4">
                            <p className="text-sm font-medium text-slate-900">
                                {user.name}
                            </p>

                            <p className="mt-1 text-xs text-slate-500">
                                {user.email}
                            </p>
                        </div>
                    )}

                    <form
                        onSubmit={handleSubmit}
                        className="space-y-5"
                    >
                        <div>
                            <label className="mb-2 block text-sm font-medium text-slate-700">
                                Registration number
                            </label>

                            <input
                                value={registrationNumber}
                                onChange={(event) =>
                                    setRegistrationNumber(event.target.value)
                                }
                                placeholder="Enter registration number"
                                autoComplete="username"
                                className="w-full rounded-xl border text-black border-slate-300 px-4 py-3 outline-none transition focus:border-slate-500 focus:ring-2 focus:ring-slate-200"
                            />
                        </div>

                        <div>
                            <label className="mb-2 block text-sm font-medium text-slate-700">
                                ERP password
                            </label>

                            <input
                                type="password"
                                value={password}
                                onChange={(event) =>
                                    setPassword(event.target.value)
                                }
                                placeholder="Enter ERP password"
                                autoComplete="current-password"
                                className="w-full rounded-xl border text-black border-slate-300 px-4 py-3 outline-none transition focus:border-slate-500 focus:ring-2 focus:ring-slate-200"
                            />
                        </div>

                        <div>
                            <label className="mb-2 block text-sm font-medium text-slate-700">
                                Email
                            </label>

                            <input
                                type="email"
                                value={email}
                                onChange={(event) =>
                                    setEmail(event.target.value)
                                }
                                placeholder="your@email.com"
                                className="w-full rounded-xl border text-black border-slate-300 px-4 py-3 outline-none transition focus:border-slate-500 focus:ring-2 focus:ring-slate-200"
                            />

                            <p className="mt-2 text-xs text-slate-400">
                                Optional. You can link another email to this
                                account.
                            </p>
                        </div>

                        {error && (
                            <div className="rounded-xl bg-red-50 p-4 text-sm text-red-600">
                                {error}
                            </div>
                        )}

                        <button
                            type="submit"
                            disabled={submitting}
                            className="flex w-full items-center justify-center gap-2 rounded-xl bg-slate-900 px-4 py-3 font-medium text-white transition hover:bg-slate-800 disabled:cursor-not-allowed disabled:opacity-60"
                        >
                            {submitting && (
                                <Loader2 className="h-5 w-5 animate-spin" />
                            )}

                            {submitting
                                ? "Connecting..."
                                : "Connect ERP account"}
                        </button>
                    </form>

                    <p className="mt-5 text-center text-xs leading-5 text-slate-400">
                        Your ERP password is sent directly to the backend
                        over HTTPS and is stored encrypted.
                    </p>
                </div>
            </div>
        </main>
    );
}