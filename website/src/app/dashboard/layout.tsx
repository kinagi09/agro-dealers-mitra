"use client";

import { useEffect, useState } from "react";
import { useRouter, usePathname } from "next/navigation";
import Link from "next/link";
import * as api from "@/lib/api";

const navItems = [
  { href: "/dashboard", label: "Home" },
  { href: "/dashboard/fertilizer", label: "Fertilizer Licence" },
  { href: "/dashboard/pesticide", label: "Pesticide Licence" },
  { href: "/dashboard/seed", label: "Seed Licence" },
  { href: "/dashboard/notifications", label: "Notifications" },
];

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const [checked, setChecked] = useState(false);

  useEffect(() => {
    queueMicrotask(async () => {
      if (!api.isLoggedIn()) {
        router.replace("/login");
        return;
      }
      // Fails closed to /subscribe on any error (e.g. network issue) rather
      // than granting access to a dealer whose subscription can't be
      // confirmed active.
      try {
        const result = await api.getSubscriptionStatus();
        if (result.is_active !== true) {
          router.replace("/subscribe");
          return;
        }
      } catch {
        router.replace("/subscribe");
        return;
      }
      setChecked(true);
    });
  }, [router]);

  function logout() {
    api.logout();
    router.push("/login");
  }

  if (!checked) {
    return <div className="px-6 py-16 text-center text-black/50">Loading...</div>;
  }

  return (
    <div className="mx-auto flex max-w-6xl gap-8 px-6 py-10">
      <aside className="w-56 shrink-0">
        <nav className="space-y-1">
          {navItems.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className={`block rounded-lg px-3 py-2 text-sm font-medium ${
                pathname === item.href
                  ? "bg-brand-green/10 text-brand-green"
                  : "text-black/70 hover:bg-black/5"
              }`}
            >
              {item.label}
            </Link>
          ))}
          <button
            onClick={logout}
            className="mt-4 block w-full rounded-lg px-3 py-2 text-left text-sm font-medium text-red-600 hover:bg-red-50"
          >
            Logout
          </button>
        </nav>
      </aside>
      <main className="flex-1 min-w-0">{children}</main>
    </div>
  );
}
