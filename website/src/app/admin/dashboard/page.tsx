"use client";

import { useEffect, useState } from "react";
import * as adminApi from "@/lib/adminApi";
import { isoToDisplayDateString } from "@/lib/date";

type Dealer = {
  id: number;
  name: string;
  shop_name: string;
  whatsapp_number: string;
  taluka_name: string;
  district_name: string;
  state_name: string;
  created_at: string;
};
type Licence = {
  id: number;
  dealer_name: string;
  licence_type_name: string;
  licence_number: string;
  issue_date: string;
  expiry_date: string | null;
  status: string;
};
type Notification = {
  id: number;
  dealer_shop_name: string;
  channel: string;
  status: string;
  message_content: string;
  is_expiry_day: boolean;
  sent_at: string;
};

type Tab = "dealers" | "licences" | "notifications";

export default function AdminDashboardPage() {
  const [tab, setTab] = useState<Tab>("dealers");
  const [dealers, setDealers] = useState<Dealer[]>([]);
  const [licences, setLicences] = useState<Licence[]>([]);
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    queueMicrotask(async () => {
      try {
        const [d, l, n] = await Promise.all([
          adminApi.getAllDealers(),
          adminApi.getAllLicences(),
          adminApi.getAllNotifications(),
        ]);
        setDealers(d);
        setLicences(l);
        setNotifications(n);
      } catch {
        setError("Could not load data. Check your connection.");
      } finally {
        setIsLoading(false);
      }
    });
  }, []);

  if (isLoading) return <p className="text-black/50">Loading...</p>;
  if (error) return <p className="text-red-600">{error}</p>;

  const tabs: { key: Tab; label: string; count: number }[] = [
    { key: "dealers", label: "Dealers", count: dealers.length },
    { key: "licences", label: "Licences", count: licences.length },
    { key: "notifications", label: "Notifications", count: notifications.length },
  ];

  return (
    <div>
      <div className="flex gap-2 border-b border-brand-grey-border">
        {tabs.map((t) => (
          <button
            key={t.key}
            onClick={() => setTab(t.key)}
            className={`px-4 py-2 text-sm font-semibold ${
              tab === t.key
                ? "border-b-2 border-brand-green text-brand-green"
                : "text-black/50 hover:text-black"
            }`}
          >
            {t.label} ({t.count})
          </button>
        ))}
      </div>

      <div className="mt-6 overflow-x-auto">
        {tab === "dealers" && (
          <table className="w-full min-w-[700px] text-left text-sm">
            <thead>
              <tr className="border-b border-brand-grey-border text-black/50">
                <th className="py-2 pr-4">Name</th>
                <th className="py-2 pr-4">Shop</th>
                <th className="py-2 pr-4">WhatsApp</th>
                <th className="py-2 pr-4">Taluka / District / State</th>
                <th className="py-2 pr-4">Joined</th>
              </tr>
            </thead>
            <tbody>
              {dealers.map((d) => (
                <tr key={d.id} className="border-b border-brand-grey-border/60">
                  <td className="py-2 pr-4">{d.name}</td>
                  <td className="py-2 pr-4">{d.shop_name}</td>
                  <td className="py-2 pr-4">{d.whatsapp_number}</td>
                  <td className="py-2 pr-4">
                    {d.taluka_name}, {d.district_name}, {d.state_name}
                  </td>
                  <td className="py-2 pr-4">
                    {new Date(d.created_at).toLocaleDateString("en-IN")}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}

        {tab === "licences" && (
          <table className="w-full min-w-[700px] text-left text-sm">
            <thead>
              <tr className="border-b border-brand-grey-border text-black/50">
                <th className="py-2 pr-4">Dealer</th>
                <th className="py-2 pr-4">Type</th>
                <th className="py-2 pr-4">Licence No</th>
                <th className="py-2 pr-4">Issue</th>
                <th className="py-2 pr-4">Expiry</th>
                <th className="py-2 pr-4">Status</th>
              </tr>
            </thead>
            <tbody>
              {licences.map((l) => (
                <tr key={l.id} className="border-b border-brand-grey-border/60">
                  <td className="py-2 pr-4">{l.dealer_name}</td>
                  <td className="py-2 pr-4">{l.licence_type_name}</td>
                  <td className="py-2 pr-4">{l.licence_number}</td>
                  <td className="py-2 pr-4">{isoToDisplayDateString(l.issue_date)}</td>
                  <td className="py-2 pr-4">
                    {l.expiry_date ? isoToDisplayDateString(l.expiry_date) : "-"}
                  </td>
                  <td className="py-2 pr-4">{l.status}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}

        {tab === "notifications" && (
          <table className="w-full min-w-[700px] text-left text-sm">
            <thead>
              <tr className="border-b border-brand-grey-border text-black/50">
                <th className="py-2 pr-4">Dealer</th>
                <th className="py-2 pr-4">Channel</th>
                <th className="py-2 pr-4">Status</th>
                <th className="py-2 pr-4">Message</th>
                <th className="py-2 pr-4">Sent</th>
              </tr>
            </thead>
            <tbody>
              {notifications.map((n) => (
                <tr key={n.id} className="border-b border-brand-grey-border/60">
                  <td className="py-2 pr-4">{n.dealer_shop_name}</td>
                  <td className="py-2 pr-4">{n.channel}</td>
                  <td className="py-2 pr-4">{n.status}</td>
                  <td
                    className={`py-2 pr-4 max-w-xs truncate ${
                      n.is_expiry_day ? "font-semibold text-red-600" : ""
                    }`}
                    title={n.message_content}
                  >
                    {n.message_content}
                  </td>
                  <td className="py-2 pr-4">
                    {new Date(n.sent_at).toLocaleString("en-IN")}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
