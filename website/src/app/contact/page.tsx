import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Contact — Agro Dealers Mitra",
  description: "Get in touch with the Agro Dealers Mitra team.",
};

export default function ContactPage() {
  return (
    <div className="mx-auto max-w-3xl px-6 py-16">
      <h1 className="text-3xl font-bold text-brand-green">Contact Us</h1>
      <p className="mt-4 text-[15px] leading-relaxed text-black/80">
        Have a question about your account, a payment, or the app itself?
        Reach out and we&apos;ll get back to you.
      </p>

      <div className="mt-10 space-y-6">
        <div className="rounded-xl border border-brand-grey-border p-6">
          <p className="text-sm font-semibold text-black/50">Email</p>
          <a
            href="mailto:support@agrodealersmitra.in"
            className="mt-1 block text-lg font-semibold text-brand-green"
          >
            support@agrodealersmitra.in
          </a>
        </div>

        <div className="rounded-xl border border-brand-grey-border p-6">
          <p className="text-sm font-semibold text-black/50">WhatsApp</p>
          <p className="mt-1 text-lg font-semibold text-black">
            Message us on the number registered to your account
          </p>
        </div>
      </div>
    </div>
  );
}
