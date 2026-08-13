"use client";

import { useEffect, useState } from "react";
import * as api from "@/lib/api";

export default function DashboardHomePage() {
  const [shopName, setShopName] = useState<string | null>(null);

  useEffect(() => {
    api
      .getMyDealerProfile()
      .then((profile) => setShopName(profile?.shop_name ?? ""))
      .catch(() => setShopName(""));
  }, []);

  return (
    <div>
      <p className="text-sm text-black/60">Hello,</p>
      <h1 className="mt-1 text-2xl font-bold text-black">
        {shopName === null ? "..." : shopName || "Dealer"}
      </h1>
      <p className="mt-6 text-sm text-black/60">
        Use the menu on the left to view or update your Fertilizer, Pesticide,
        and Seed licences, and check your recent notifications.
      </p>
    </div>
  );
}
