import Image from "next/image";
import Link from "next/link";

export default function Header() {
  return (
    <header className="border-b border-brand-grey-border bg-white">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
        <Link href="/" className="flex items-center gap-2">
          <Image src="/logo.png" alt="" width={28} height={28} priority />
          <span className="text-lg font-bold text-brand-green">
            Agro Dealers Mitra
          </span>
        </Link>
        <nav className="flex items-center gap-6 text-sm font-medium">
          <Link href="/#features" className="hover:text-brand-green">
            Features
          </Link>
          <Link href="/#how-it-works" className="hover:text-brand-green">
            How it works
          </Link>
          <Link href="/login" className="hover:text-brand-green">
            Login
          </Link>
          <Link
            href="/#get-the-app"
            className="rounded-lg bg-brand-yellow px-4 py-2 font-bold text-black hover:brightness-95"
          >
            Get the App
          </Link>
        </nav>
      </div>
    </header>
  );
}
