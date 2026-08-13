"use client";

import { useEffect, useState } from "react";
import * as api from "@/lib/api";

type Notification = {
  id: number;
  message_content: string;
  is_expiry_day: boolean;
  sent_at: string;
};

export default function NotificationsPage() {
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    api
      .getMyNotifications()
      .then(setNotifications)
      .catch(() => setError("Could not load notifications. Check your connection."))
      .finally(() => setIsLoading(false));
  }, []);

  if (isLoading) return <p className="text-black/50">Loading...</p>;
  if (error) return <p className="text-red-600">{error}</p>;

  return (
    <div>
      <h1 className="text-2xl font-bold text-black">Notifications</h1>
      {notifications.length === 0 ? (
        <p className="mt-6 text-black/50">No notifications yet.</p>
      ) : (
        <div className="mt-6 space-y-3">
          {notifications.map((n) => (
            <div key={n.id} className="rounded-xl border border-brand-grey-border p-4">
              <p
                className={
                  n.is_expiry_day
                    ? "font-semibold text-red-600"
                    : "text-black/80"
                }
              >
                {n.message_content}
              </p>
              <p className="mt-1 text-xs text-black/40">
                {new Date(n.sent_at).toLocaleString("en-IN")}
              </p>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
