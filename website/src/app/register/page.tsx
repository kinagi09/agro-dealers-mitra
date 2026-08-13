"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import * as api from "@/lib/api";

const inputClass =
  "w-full rounded-lg border border-brand-grey-border px-4 py-2.5 text-[15px] outline-none focus:border-brand-green focus:ring-1 focus:ring-brand-green disabled:bg-black/5";

const buttonClass =
  "w-full rounded-lg bg-brand-green px-4 py-2.5 font-semibold text-white transition hover:brightness-95 disabled:opacity-50";

export default function RegisterPage() {
  const router = useRouter();

  const [whatsappNumber, setWhatsappNumber] = useState("");
  const [otpCode, setOtpCode] = useState("");
  const [otpSent, setOtpSent] = useState(false);
  const [otpVerified, setOtpVerified] = useState(false);
  const [name, setName] = useState("");
  const [shopName, setShopName] = useState("");
  const [address, setAddress] = useState("");

  const [states, setStates] = useState<Array<{ id: number; name: string }>>([]);
  const [districts, setDistricts] = useState<Array<{ id: number; name: string }>>([]);
  const [talukas, setTalukas] = useState<Array<{ id: number; name: string }>>([]);
  const [stateId, setStateId] = useState("");
  const [districtId, setDistrictId] = useState("");
  const [talukaId, setTalukaId] = useState("");

  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [statesLoaded, setStatesLoaded] = useState(false);

  async function loadStatesOnce() {
    if (statesLoaded) return;
    try {
      setStates(await api.getStates());
      setStatesLoaded(true);
    } catch {
      setError("Could not load states. Check your connection.");
    }
  }

  async function onStateChange(value: string) {
    setStateId(value);
    setDistrictId("");
    setTalukaId("");
    setDistricts([]);
    setTalukas([]);
    if (value) setDistricts(await api.getDistricts(Number(value)));
  }

  async function onDistrictChange(value: string) {
    setDistrictId(value);
    setTalukaId("");
    setTalukas([]);
    if (value) setTalukas(await api.getTalukas(Number(value)));
  }

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
      await api.sendOtp(number, "register");
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

  async function verifyOtp() {
    setIsLoading(true);
    setError(null);
    try {
      await api.verifyOtp(whatsappNumber.trim(), otpCode.trim());
      setOtpVerified(true);
      loadStatesOnce();
    } catch {
      setError("Invalid or expired OTP. Try again.");
    } finally {
      setIsLoading(false);
    }
  }

  function describeRegistrationError(e: unknown): string {
    if (e instanceof api.ApiError && e.data && typeof e.data === "object") {
      const data = e.data as Record<string, unknown>;
      if (typeof data.detail === "string") return data.detail;
      const firstField = Object.keys(data)[0];
      if (firstField) {
        const firstError = data[firstField];
        const errorText = Array.isArray(firstError)
          ? firstError.join(", ")
          : String(firstError);
        return `${firstField}: ${errorText}`;
      }
    }
    return "Registration failed. Please try again.";
  }

  async function register(e: React.FormEvent) {
    e.preventDefault();
    if (!name.trim()) return setError("The Name field is not filled, please do fill it.");
    if (!shopName.trim())
      return setError("The Shop Name field is not filled, please do fill it.");
    if (!address.trim())
      return setError("The Address field is not filled, please do fill it.");
    if (!stateId) return setError("The State field is not filled, please do fill it.");
    if (!districtId)
      return setError("The District field is not filled, please do fill it.");
    if (!talukaId) return setError("The Taluka field is not filled, please do fill it.");

    setIsLoading(true);
    setError(null);
    try {
      await api.registerDealer({
        whatsapp_number: whatsappNumber.trim(),
        name: name.trim(),
        shop_name: shopName.trim(),
        address: address.trim(),
        taluka: Number(talukaId),
      });
      router.push("/dashboard");
    } catch (e) {
      setError(describeRegistrationError(e));
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <div className="mx-auto max-w-md px-6 py-16">
      <h1 className="text-2xl font-bold text-brand-green">Register</h1>
      <p className="mt-1 text-sm text-black/60">
        Create your dealer account with your WhatsApp number.
      </p>

      <form onSubmit={register} className="mt-8 space-y-4">
        <input
          className={inputClass}
          placeholder="WhatsApp Number"
          type="tel"
          maxLength={10}
          value={whatsappNumber}
          disabled={otpSent}
          onChange={(e) => setWhatsappNumber(e.target.value.replace(/\D/g, ""))}
        />

        {!otpSent && (
          <button
            type="button"
            className={buttonClass}
            disabled={isLoading}
            onClick={sendOtp}
          >
            {isLoading ? "Sending..." : "Send OTP"}
          </button>
        )}

        {otpSent && !otpVerified && (
          <>
            <input
              className={inputClass}
              placeholder="Enter OTP"
              inputMode="numeric"
              maxLength={6}
              value={otpCode}
              onChange={(e) => setOtpCode(e.target.value.replace(/\D/g, ""))}
            />
            <button
              type="button"
              className={buttonClass}
              disabled={isLoading}
              onClick={verifyOtp}
            >
              {isLoading ? "Verifying..." : "Verify OTP"}
            </button>
          </>
        )}

        {otpVerified && (
          <>
            <hr className="border-brand-grey-border" />

            <input
              className={inputClass}
              placeholder="Person Full Name"
              value={name}
              onChange={(e) => setName(e.target.value)}
            />
            <input
              className={inputClass}
              placeholder="Firm Name"
              value={shopName}
              onChange={(e) => setShopName(e.target.value)}
            />
            <textarea
              className={inputClass}
              placeholder="Firm Address"
              rows={2}
              value={address}
              onChange={(e) => setAddress(e.target.value)}
            />

            <select
              className={inputClass}
              value={stateId}
              onFocus={loadStatesOnce}
              onChange={(e) => onStateChange(e.target.value)}
            >
              <option value="">Select State</option>
              {states.map((s) => (
                <option key={s.id} value={s.id}>
                  {s.name}
                </option>
              ))}
            </select>

            <select
              className={inputClass}
              value={districtId}
              disabled={!stateId}
              onChange={(e) => onDistrictChange(e.target.value)}
            >
              <option value="">Select District</option>
              {districts.map((d) => (
                <option key={d.id} value={d.id}>
                  {d.name}
                </option>
              ))}
            </select>

            <select
              className={inputClass}
              value={talukaId}
              disabled={!districtId}
              onChange={(e) => setTalukaId(e.target.value)}
            >
              <option value="">Select Taluka</option>
              {talukas.map((t) => (
                <option key={t.id} value={t.id}>
                  {t.name}
                </option>
              ))}
            </select>

            <button type="submit" className={buttonClass} disabled={isLoading}>
              {isLoading ? "Registering..." : "Complete Registration"}
            </button>
          </>
        )}

        {error && <p className="text-sm text-red-600">{error}</p>}
      </form>

      <p className="mt-6 text-center text-sm text-black/60">
        Already have an account?{" "}
        <a href="/login" className="font-semibold text-brand-green">
          Log in
        </a>
      </p>
    </div>
  );
}
