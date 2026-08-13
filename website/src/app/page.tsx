import Link from "next/link";

const licenceTypes = [
  {
    name: "Fertilizer",
    blurb: "Retailer, District Wholesale, and State Wholesale licences.",
  },
  {
    name: "Pesticide",
    blurb: "District and State dealer licences, tracked per source company.",
  },
  {
    name: "Seed",
    blurb: "District and State dealer licences for seed distribution.",
  },
];

const features = [
  {
    title: "Reminders that actually fire",
    description:
      "Get notified 30, 15, and 7 days before a licence expires — and again on the day itself.",
  },
  {
    title: "One licence per type, tracked properly",
    description:
      "Hold a Retailer, District, and State licence side by side without losing track of which is which.",
  },
  {
    title: "No password to forget",
    description:
      "Log in with your WhatsApp number and a one-time code. Nothing else to remember.",
  },
  {
    title: "Source companies, not just licences",
    description:
      "Track every source company and manufacturer under each Fertilizer or Pesticide licence, each with its own validity date.",
  },
];

const steps = [
  {
    step: "1",
    title: "Register with your WhatsApp number",
    description:
      "No email, no password — just your shop details and a one-time code.",
  },
  {
    step: "2",
    title: "Add your licences",
    description:
      "Fertilizer, Pesticide, and Seed — add the licence types your shop actually holds.",
  },
  {
    step: "3",
    title: "Get reminded before they lapse",
    description:
      "We track every expiry date and let you know with plenty of time to renew.",
  },
];

export default function Home() {
  return (
    <>
      <section className="bg-gradient-to-b from-white to-[#fafaf5]">
        <div className="mx-auto flex max-w-6xl flex-col items-center gap-6 px-6 py-20 text-center sm:py-28">
          <span className="rounded-full bg-brand-yellow/20 px-4 py-1 text-sm font-semibold text-brand-green">
            Built for agricultural input dealers
          </span>
          <h1 className="max-w-3xl text-4xl font-bold tracking-tight text-[#1a1a1a] sm:text-5xl">
            Never miss a licence renewal again
          </h1>
          <p className="max-w-2xl text-lg text-black/60">
            Agro Dealers Mitra keeps every Fertilizer, Pesticide, and Seed
            licence you hold in one place, and reminds you well before any of
            them expire.
          </p>
          <div className="mt-4 flex flex-wrap items-center justify-center gap-4">
            <Link
              href="#get-the-app"
              className="rounded-lg bg-brand-yellow px-6 py-3 font-bold text-black shadow-sm hover:brightness-95"
            >
              Get the App
            </Link>
            <Link
              href="#how-it-works"
              className="rounded-lg border border-brand-green px-6 py-3 font-semibold text-brand-green hover:bg-brand-green/5"
            >
              See how it works
            </Link>
          </div>
        </div>
      </section>

      <section className="mx-auto max-w-6xl px-6 py-16">
        <div className="grid gap-6 sm:grid-cols-3">
          {licenceTypes.map((l) => (
            <div
              key={l.name}
              className="rounded-xl border border-brand-grey-border bg-white p-6"
            >
              <h3 className="text-lg font-bold text-brand-green">
                {l.name} Licence
              </h3>
              <p className="mt-2 text-sm text-black/60">{l.blurb}</p>
            </div>
          ))}
        </div>
      </section>

      <section id="features" className="bg-[#fafaf5] py-20">
        <div className="mx-auto max-w-6xl px-6">
          <h2 className="text-center text-3xl font-bold">
            Everything you need, nothing you don&apos;t
          </h2>
          <div className="mt-12 grid gap-8 sm:grid-cols-2">
            {features.map((f) => (
              <div key={f.title} className="flex gap-4">
                <div className="mt-1 h-2 w-2 flex-shrink-0 rounded-full bg-brand-yellow" />
                <div>
                  <h3 className="font-bold">{f.title}</h3>
                  <p className="mt-1 text-sm text-black/60">
                    {f.description}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section id="how-it-works" className="mx-auto max-w-6xl px-6 py-20">
        <h2 className="text-center text-3xl font-bold">How it works</h2>
        <div className="mt-12 grid gap-8 sm:grid-cols-3">
          {steps.map((s) => (
            <div key={s.step} className="text-center">
              <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-brand-green text-lg font-bold text-white">
                {s.step}
              </div>
              <h3 className="mt-4 font-bold">{s.title}</h3>
              <p className="mt-2 text-sm text-black/60">{s.description}</p>
            </div>
          ))}
        </div>
      </section>

      <section id="get-the-app" className="bg-brand-green py-20">
        <div className="mx-auto flex max-w-6xl flex-col items-center gap-4 px-6 text-center">
          <h2 className="text-3xl font-bold text-white">
            Get Agro Dealers Mitra
          </h2>
          <p className="max-w-xl text-white/80">
            The app is currently available for Android. A Play Store listing
            is coming soon — check back here for the download link.
          </p>
          <span className="mt-4 rounded-lg bg-white/10 px-6 py-3 font-semibold text-white/70">
            Coming soon to Google Play
          </span>
        </div>
      </section>
    </>
  );
}
