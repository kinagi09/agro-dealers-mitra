import { ApiError } from "@/lib/api";

const baseUrl =
  process.env.NEXT_PUBLIC_API_BASE_URL || "http://localhost:8000/api";

// Separate token storage from the dealer portal (src/lib/api.ts) -
// admin/staff sessions and dealer sessions are never the same browser
// session in practice, but keeping the keys distinct avoids any risk of
// one silently clobbering the other.

export function isStaffLoggedIn(): boolean {
  if (typeof window === "undefined") return false;
  return localStorage.getItem("staff_refresh_token") !== null;
}

function getAccessToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem("staff_access_token");
}

function getRefreshToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem("staff_refresh_token");
}

export function staffLogout() {
  localStorage.removeItem("staff_access_token");
  localStorage.removeItem("staff_refresh_token");
}

async function handleResponse(response: Response) {
  const text = await response.text();
  const data = text ? JSON.parse(text) : null;
  if (!response.ok) throw new ApiError(data);
  return data;
}

export async function staffLogin(username: string, password: string) {
  const response = await fetch(`${baseUrl}/auth/staff-login/`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ username, password }),
  });
  const data = await handleResponse(response);
  localStorage.setItem("staff_access_token", data.access);
  localStorage.setItem("staff_refresh_token", data.refresh);
  return data;
}

async function refreshAccessToken(): Promise<boolean> {
  const refreshToken = getRefreshToken();
  if (!refreshToken) return false;
  const response = await fetch(`${baseUrl}/token/refresh/`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ refresh: refreshToken }),
  });
  if (!response.ok) return false;
  const data = await response.json();
  localStorage.setItem("staff_access_token", data.access);
  return true;
}

async function authHeaders(): Promise<Record<string, string>> {
  const token = getAccessToken();
  return {
    "Content-Type": "application/json",
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
  };
}

async function authorizedRequest(
  request: (headers: Record<string, string>) => Promise<Response>
) {
  let response = await request(await authHeaders());
  if (response.status === 401) {
    const refreshed = await refreshAccessToken();
    if (!refreshed) {
      staffLogout();
      throw new ApiError({ detail: "Session expired" });
    }
    response = await request(await authHeaders());
  }
  return handleResponse(response);
}

export async function getAllDealers() {
  return authorizedRequest((headers) => fetch(`${baseUrl}/dealers/`, { headers }));
}

export async function getAllLicences() {
  return authorizedRequest((headers) => fetch(`${baseUrl}/licences/`, { headers }));
}

export async function getAllNotifications() {
  return authorizedRequest((headers) =>
    fetch(`${baseUrl}/notifications/`, { headers })
  );
}

export async function getLicenceTypesMap() {
  const categories = await authorizedRequest((headers) =>
    fetch(`${baseUrl}/licence-categories/`, { headers })
  );
  const typesByCategory: Record<number, Array<{ id: number; name: string }>> = {};
  for (const c of categories) {
    typesByCategory[c.id] = await authorizedRequest((headers) =>
      fetch(`${baseUrl}/licence-types/?category=${c.id}`, { headers })
    );
  }
  return { categories, typesByCategory };
}
