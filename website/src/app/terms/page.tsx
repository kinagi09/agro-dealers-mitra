import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Terms of Service — Agro Dealers Mitra",
  description: "The terms that govern use of the Agro Dealers Mitra app and website.",
};

export default function TermsPage() {
  return (
    <div className="mx-auto max-w-3xl px-6 py-16">
      <h1 className="text-3xl font-bold text-brand-green">Terms of Service</h1>
      <p className="mt-2 text-sm text-black/50">Last updated: 14 August 2026</p>

      <div className="mt-10 space-y-8 text-[15px] leading-relaxed text-black/80">
        <section>
          <h2 className="text-lg font-bold text-black">1. Acceptance of terms</h2>
          <p className="mt-2">
            By registering for or using the Agro Dealers Mitra app or
            website, you agree to these Terms of Service. If you do not
            agree, please do not use the service.
          </p>
        </section>

        <section>
          <h2 className="text-lg font-bold text-black">2. The service</h2>
          <p className="mt-2">
            Agro Dealers Mitra is a paid subscription service that helps
            agricultural input dealers track Fertilizer, Pesticide, and
            Seed licence expiry dates and receive renewal reminders. It is
            a record-keeping and reminder tool - it does not file, submit,
            or renew licences with any government authority on your
            behalf, and reminders are sent on a best-effort basis.
          </p>
        </section>

        <section>
          <h2 className="text-lg font-bold text-black">3. Accounts</h2>
          <p className="mt-2">
            You register using your WhatsApp number and a one-time code -
            we do not use passwords. You are responsible for keeping access
            to that WhatsApp number secure, since it is how your account is
            authenticated and how reminders are delivered.
          </p>
        </section>

        <section>
          <h2 className="text-lg font-bold text-black">4. Subscription and payments</h2>
          <p className="mt-2">
            Access requires an active yearly subscription, paid via
            Razorpay at registration and renewed annually. Prices are shown
            in the app before payment. See our{" "}
            <a href="/refund-policy" className="text-brand-green underline">
              Refund &amp; Cancellation Policy
            </a>{" "}
            for cancellation and refund terms.
          </p>
        </section>

        <section>
          <h2 className="text-lg font-bold text-black">5. Your responsibilities</h2>
          <p className="mt-2">
            You are responsible for the accuracy of the licence numbers,
            dates, and other information you enter. Agro Dealers Mitra is
            not liable for penalties, fines, or losses arising from an
            expired or non-renewed licence, incorrect data entry, or a
            missed or delayed reminder.
          </p>
        </section>

        <section>
          <h2 className="text-lg font-bold text-black">6. Termination</h2>
          <p className="mt-2">
            You may stop using the service and request account deletion at
            any time via our{" "}
            <a href="/contact" className="text-brand-green underline">
              Contact
            </a>{" "}
            page. We may suspend or terminate accounts that violate these
            terms or misuse the service.
          </p>
        </section>

        <section>
          <h2 className="text-lg font-bold text-black">7. Changes to these terms</h2>
          <p className="mt-2">
            We may update these terms from time to time. Continued use of
            the service after an update constitutes acceptance of the
            revised terms.
          </p>
        </section>

        <section>
          <h2 className="text-lg font-bold text-black">8. Contact us</h2>
          <p className="mt-2">
            Questions about these terms can be sent via our{" "}
            <a href="/contact" className="text-brand-green underline">
              Contact
            </a>{" "}
            page.
          </p>
        </section>
      </div>
    </div>
  );
}
