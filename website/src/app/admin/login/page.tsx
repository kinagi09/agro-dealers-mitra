"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import * as adminApi from "@/lib/adminApi";
import { ApiError } from "@/lib/api";

const inputClass =
  "w-full rounded-lg border border-brand-grey-border px-4 py-2.5 text-[15px] outline-none focus:border-brand-green focus:ring-1 focus:ring-brand-green";

const buttonClass =
  "w-full rounded-lg bg-brand-green px-4 py-2.5 font-semibold text-white transition hover:brightness-95 disabled:opacity-50";

export default function AdminLoginPage() {
  const router = useRouter();
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setIsLoading(true);
    setError(null);
    try {
      await adminApi.staffLogin(username.trim(), password);
      router.push("/admin/dashboard");
    } catch (e) {
      const detail =
        e instanceof ApiError ? "Invalid staff username or password." : "Login failed.";
      setError(detail);
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <div className="mx-auto max-w-md px-6 py-16">
      <h1 className="text-2xl font-bold text-brand-green">Staff Login</h1>
      <p className="mt-1 text-sm text-black/60">
        For internal use only. Dealers should use the regular Login page.
      </p>

      <form onSubmit={submit} className="mt-8 space-y-4">
        <input
          className={inputClass}
          placeholder="Username"
          value={username}
          onChange={(e) => setUsername(e.target.value)}
        />
        <input
          className={inputClass}
          placeholder="Password"
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
        />
        {error && <p className="text-sm text-red-600">{error}</p>}
        <button type="submit" className={buttonClass} disabled={isLoading}>
          {isLoading ? "Logging in..." : "Log in"}
        </button>
      </form>
    </div>
  );
}
