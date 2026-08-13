import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Refund & Cancellation Policy — Agro Dealers Mitra",
  description: "Refund and cancellation terms for the Agro Dealers Mitra subscription.",
};

export default function RefundPolicyPage() {
  return (
    <div className="mx-auto max-w-3xl px-6 py-16">
      <h1 className="text-3xl font-bold text-brand-green">
        Refund &amp; Cancellation Policy
      </h1>
      <p className="mt-2 text-sm text-black/50">Last updated: 14 August 2026</p>

      <div className="mt-10 space-y-8 text-[15px] leading-relaxed text-black/80">
        <section>
          <h2 className="text-lg font-bold text-black">1. Subscription</h2>
          <p className="mt-2">
            Agro Dealers Mitra is billed as a yearly subscription, paid via
            Razorpay. Your subscription gives you access to the app for a
            12-month period from the date of successful payment.
          </p>
        </section>

        <section>
          <h2 className="text-lg font-bold text-black">2. Cancellation</h2>
          <p className="mt-2">
            You can cancel your subscription at any time by contacting us
            (see our{" "}
            <a href="/contact" className="text-brand-green underline">
              Contact
            </a>{" "}
            page). Cancelling stops the next renewal charge - it does not
            automatically refund the current subscription period.
          </p>
        </section>

        <section>
          <h2 className="text-lg font-bold text-black">3. Refunds</h2>
          <p className="mt-2">
            Because the service is a digital subscription that grants
            immediate access on payment, we do not offer refunds for the
            current subscription period once payment has succeeded, except
            in the following cases:
          </p>
          <ul className="mt-2 list-disc space-y-1 pl-5">
            <li>
              A duplicate or erroneous charge (e.g. billed twice for the
              same period).
            </li>
            <li>
              A payment that was deducted but never activated a
              subscription due to a technical error on our end.
            </li>
          </ul>
          <p className="mt-2">
            Eligible refunds are processed back to the original payment
            method via Razorpay, typically within 5-7 business days of
            approval.
          </p>
        </section>

        <section>
          <h2 className="text-lg font-bold text-black">4. Requesting a refund</h2>
          <p className="mt-2">
            To request a refund, contact us within 7 days of the charge via
            our{" "}
            <a href="/contact" className="text-brand-green underline">
              Contact
            </a>{" "}
            page with your registered WhatsApp number and the payment
            date.
          </p>
        </section>
      </div>
    </div>
  );
}
