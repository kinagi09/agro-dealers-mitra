import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Privacy Policy — Agro Dealers Mitra",
  description: "How Agro Dealers Mitra collects, uses, and protects your data.",
};

export default function PrivacyPolicyPage() {
  return (
    <div className="mx-auto max-w-3xl px-6 py-16">
      <h1 className="text-3xl font-bold text-brand-green">Privacy Policy</h1>
      <p className="mt-2 text-sm text-black/50">Last updated: 14 August 2026</p>

      <div className="mt-10 space-y-8 text-[15px] leading-relaxed text-black/80">
        <section>
          <h2 className="text-lg font-bold text-black">1. Who we are</h2>
          <p className="mt-2">
            Agro Dealers Mitra (&ldquo;we&rdquo;, &ldquo;us&rdquo;) provides a
            mobile app and website that help agricultural input dealers track
            Fertilizer, Pesticide, and Seed licence renewals. This policy
            explains what information we collect through the app and
            website, and how we use it.
          </p>
        </section>

        <section>
          <h2 className="text-lg font-bold text-black">
            2. Information we collect
          </h2>
          <ul className="mt-2 list-disc space-y-1 pl-5">
            <li>
              <strong>Account details:</strong> your name, shop name,
              WhatsApp number, address, and taluka/district/state.
            </li>
            <li>
              <strong>Licence data:</strong> licence numbers, issue and
              expiry dates, and source/company entries you enter for your
              Fertilizer, Pesticide, and Seed licences.
            </li>
            <li>
              <strong>Device information:</strong> a push-notification
              token (via Firebase Cloud Messaging) so we can send you
              renewal reminders, and your notification preferences.
            </li>
            <li>
              <strong>Payment information:</strong> subscription payments
              are processed by Razorpay. We do not receive or store your
              card, UPI, or bank details - only the payment status and
              subscription dates.
            </li>
          </ul>
        </section>

        <section>
          <h2 className="text-lg font-bold text-black">
            3. How we use your information
          </h2>
          <p className="mt-2">
            We use your information to operate your account, track your
            licences, and send you renewal reminders (in-app push
            notifications and, where enabled, WhatsApp messages) before a
            licence expires. We do not sell your information to third
            parties.
          </p>
        </section>

        <section>
          <h2 className="text-lg font-bold text-black">
            4. How we protect your information
          </h2>
          <p className="mt-2">
            Login is passwordless, via a one-time code sent to your
            WhatsApp number - we never ask for or store a password. Data is
            transmitted over encrypted (HTTPS) connections and stored on
            secured servers accessible only to authorised personnel.
          </p>
        </section>

        <section>
          <h2 className="text-lg font-bold text-black">
            5. Your choices
          </h2>
          <p className="mt-2">
            You can update your notification preferences at any time in the
            app. You can request deletion of your account and all
            associated data - licences, entries, and notification history -
            by contacting us (see our{" "}
            <a href="/contact" className="text-brand-green underline">
              Contact
            </a>{" "}
            page). Deleting your account permanently removes this data; it
            is not recoverable afterwards.
          </p>
        </section>

        <section>
          <h2 className="text-lg font-bold text-black">
            6. Changes to this policy
          </h2>
          <p className="mt-2">
            We may update this policy from time to time. Material changes
            will be reflected by updating the &ldquo;Last updated&rdquo;
            date above.
          </p>
        </section>

        <section>
          <h2 className="text-lg font-bold text-black">7. Contact us</h2>
          <p className="mt-2">
            Questions about this policy or your data can be sent via our{" "}
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
