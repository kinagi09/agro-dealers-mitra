"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Script from "next/script";
import * as api from "@/lib/api";

declare global {
  interface Window {
    Razorpay: new (options: Record<string, unknown>) => {
      open: () => void;
    };
  }
}

const buttonClass =
  "w-full rounded-lg bg-brand-green px-4 py-2.5 font-semibold text-white transition hover:brightness-95 disabled:opacity-50";

export default function SubscribePage() {
  const router = useRouter();
  const [isLoading, setIsLoading] = useState(false);
  const [scriptReady, setScriptReady] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function startCheckout() {
    setIsLoading(true);
    setError(null);
    try {
      const subscription = await api.createSubscription();
      const razorpay = new window.Razorpay({
        key: subscription.key_id,
        subscription_id: subscription.subscription_id,
        name: "Agro Dealers Mitra",
        description: "Yearly Subscription",
        theme: { color: "#216E39" },
        handler: async (response: {
          razorpay_payment_id: string;
          razorpay_subscription_id: string;
          razorpay_signature: string;
        }) => {
          try {
            await api.verifySubscription({
              razorpay_payment_id: response.razorpay_payment_id,
              razorpay_subscription_id: response.razorpay_subscription_id,
              razorpay_signature: response.razorpay_signature,
            });
            router.push("/dashboard");
          } catch {
            setError(
              "Payment succeeded but could not be verified. Please contact support."
            );
            setIsLoading(false);
          }
        },
        modal: {
          ondismiss: () => setIsLoading(false),
        },
      });
      razorpay.open();
    } catch {
      setError("Could not start payment. Please try again.");
      setIsLoading(false);
    }
  }

  return (
    <div className="mx-auto max-w-md px-6 py-16 text-center">
      <Script
        src="https://checkout.razorpay.com/v1/checkout.js"
        strategy="afterInteractive"
        onLoad={() => setScriptReady(true)}
      />
      <h1 className="text-2xl font-bold text-brand-green">
        Subscribe to continue
      </h1>
      <p className="mt-2 text-sm text-black/60">
        Track your Fertilizer, Pesticide, and Seed licences and get renewal
        reminders.
      </p>
      <p className="mt-8 text-4xl font-bold">₹499 / year</p>

      {error && <p className="mt-6 text-sm text-red-600">{error}</p>}

      <button
        className={`${buttonClass} mt-8`}
        disabled={isLoading || !scriptReady}
        onClick={startCheckout}
      >
        {isLoading ? "Please wait..." : "Subscribe Now"}
      </button>
    </div>
  );
}
