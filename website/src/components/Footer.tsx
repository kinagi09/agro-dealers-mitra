import Link from "next/link";

export default function Footer() {
  return (
    <footer className="border-t border-brand-grey-border bg-white">
      <div className="mx-auto max-w-6xl px-6 py-10 text-sm text-black/60">
        <div className="flex flex-col items-start justify-between gap-6 sm:flex-row sm:items-center">
          <p className="font-semibold text-brand-green">
            Agro Dealers Mitra
          </p>
          <nav className="flex flex-wrap items-center gap-x-6 gap-y-2">
            <Link href="/privacy-policy" className="hover:text-brand-green">
              Privacy Policy
            </Link>
            <Link href="/terms" className="hover:text-brand-green">
              Terms of Service
            </Link>
            <Link href="/refund-policy" className="hover:text-brand-green">
              Refund &amp; Cancellation
            </Link>
            <Link href="/contact" className="hover:text-brand-green">
              Contact
            </Link>
          </nav>
          <p>
            &copy; {new Date().getFullYear()} Agro Dealers Mitra. All rights
            reserved.
          </p>
        </div>
      </div>
    </footer>
  );
}
