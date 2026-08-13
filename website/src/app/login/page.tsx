"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import * as api from "@/lib/api";

const inputClass =
  "w-full rounded-lg border border-brand-grey-border px-4 py-2.5 text-[15px] outline-none focus:border-brand-green focus:ring-1 focus:ring-brand-green disabled:bg-black/5";

const buttonClass =
  "w-full rounded-lg bg-brand-green px-4 py-2.5 font-semibold text-white transition hover:brightness-95 disabled:opacity-50";

export default function LoginPage() {
  const router = useRouter();

  const [whatsappNumber, setWhatsappNumber] = useState("");
  const [otpCode, setOtpCode] = useState("");
  const [otpSent, setOtpSent] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function sendOtp() {
    const number = whatsappNumber.trim();
    if (!number) {
      setError("Please enter your WhatsApp number first.");
      return;
    }
    if (number.length !== 10) {
      setError("Please enter a valid 10-digit WhatsApp number.");
      return;
    }
    setIsLoading(true);
    setError(null);
    try {
      await api.sendOtp(number, "login");
      setOtpSent(true);
    } catch (e) {
      const detail =
        e instanceof api.ApiError && e.data && typeof e.data === "object"
          ? (e.data as { detail?: string }).detail
          : null;
      setError(detail || "Failed to send OTP. Check the number and try again.");
    } finally {
      setIsLoading(false);
    }
  }

  async function verifyAndLogin(e: React.FormEvent) {
    e.preventDefault();
    setIsLoading(true);
    setError(null);
    try {
      await api.login(whatsappNumber.trim(), otpCode.trim());
      router.push("/dashboard");
    } catch {
      setError("Invalid or expired OTP. Try again.");
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <div className="mx-auto max-w-md px-6 py-16">
      <h1 className="text-2xl font-bold text-brand-green">Login</h1>
      <p className="mt-1 text-sm text-black/60">Enter your details to login.</p>

      <form onSubmit={verifyAndLogin} className="mt-8 space-y-4">
        <input
          className={inputClass}
          placeholder="Registered WhatsApp Number"
          type="tel"
          maxLength={10}
          value={whatsappNumber}
          disabled={otpSent}
          onChange={(e) => setWhatsappNumber(e.target.value.replace(/\D/g, ""))}
        />

        {otpSent && (
          <input
            className={inputClass}
            placeholder="Enter OTP"
            inputMode="numeric"
            maxLength={6}
            value={otpCode}
            onChange={(e) => setOtpCode(e.target.value.replace(/\D/g, ""))}
          />
        )}

        {error && <p className="text-sm text-red-600">{error}</p>}

        <button
          type={otpSent ? "submit" : "button"}
          className={buttonClass}
          disabled={isLoading}
          onClick={otpSent ? undefined : sendOtp}
        >
          {isLoading ? "Please wait..." : otpSent ? "Verify & Login" : "Send OTP"}
        </button>
      </form>

      <p className="mt-6 text-center text-sm text-black/60">
        Don&apos;t have an account?{" "}
        <a href="/register" className="font-semibold text-brand-green">
          Sign Up
        </a>
      </p>
    </div>
  );
}
