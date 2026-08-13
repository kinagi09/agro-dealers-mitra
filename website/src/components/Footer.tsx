export default function Footer() {
  return (
    <footer className="border-t border-brand-grey-border bg-white">
      <div className="mx-auto max-w-6xl px-6 py-10 text-sm text-black/60">
        <div className="flex flex-col items-start justify-between gap-4 sm:flex-row sm:items-center">
          <p className="font-semibold text-brand-green">
            Agro Dealers Mitra
          </p>
          <p>
            &copy; {new Date().getFullYear()} Agro Dealers Mitra. All rights
            reserved.
          </p>
        </div>
      </div>
    </footer>
  );
}
