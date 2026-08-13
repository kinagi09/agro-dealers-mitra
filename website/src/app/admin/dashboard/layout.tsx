"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import * as adminApi from "@/lib/adminApi";

export default function AdminDashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const router = useRouter();
  const [checked, setChecked] = useState(false);

  useEffect(() => {
    queueMicrotask(() => {
      if (!adminApi.isStaffLoggedIn()) {
        router.replace("/admin/login");
      } else {
        setChecked(true);
      }
    });
  }, [router]);

  function logout() {
    adminApi.staffLogout();
    router.push("/admin/login");
  }

  if (!checked) {
    return <div className="px-6 py-16 text-center text-black/50">Loading...</div>;
  }

  return (
    <div className="mx-auto max-w-6xl px-6 py-10">
      <div className="flex items-center justify-between border-b border-brand-grey-border pb-4">
        <h1 className="text-xl font-bold text-brand-green">Staff Dashboard</h1>
        <button
          onClick={logout}
          className="rounded-lg border border-brand-grey-border px-4 py-2 text-sm font-semibold text-red-600 hover:bg-red-50"
        >
          Logout
        </button>
      </div>
      <div className="mt-6">{children}</div>
    </div>
  );
}
