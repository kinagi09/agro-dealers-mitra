const baseUrl =
  process.env.NEXT_PUBLIC_API_BASE_URL || "http://localhost:8000/api";

export class ApiError extends Error {
  data: unknown;
  constructor(data: unknown) {
    super(typeof data === "string" ? data : JSON.stringify(data));
    this.data = data;
  }
}

async function handleResponse(response: Response) {
  const text = await response.text();
  const data = text ? JSON.parse(text) : null;
  if (!response.ok) throw new ApiError(data);
  return data;
}

// ---------- TOKEN STORAGE ----------
// localStorage, mirroring the mobile app's straightforward "no server
// session, just a bearer token" approach - simplest thing that works for a
// dealer-facing portal with no sensitive server-rendered pages behind it.

export function getAccessToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem("access_token");
}

export function getRefreshToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem("refresh_token");
}

export function isLoggedIn(): boolean {
  return getRefreshToken() !== null;
}

function storeTokens(data: { access: string; refresh: string; dealer_id: number }) {
  localStorage.setItem("access_token", data.access);
  localStorage.setItem("refresh_token", data.refresh);
  localStorage.setItem("dealer_id", String(data.dealer_id));
}

export function logout() {
  localStorage.removeItem("access_token");
  localStorage.removeItem("refresh_token");
  localStorage.removeItem("dealer_id");
}

// ---------- AUTH ----------

export async function sendOtp(whatsappNumber: string, purpose: "register" | "login") {
  const response = await fetch(`${baseUrl}/auth/send-otp/`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ whatsapp_number: whatsappNumber, purpose }),
  });
  return handleResponse(response);
}

export async function verifyOtp(whatsappNumber: string, otpCode: string) {
  const response = await fetch(`${baseUrl}/auth/verify-otp/`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ whatsapp_number: whatsappNumber, otp_code: otpCode }),
  });
  return handleResponse(response);
}

export async function registerDealer(payload: {
  whatsapp_number: string;
  name: string;
  shop_name: string;
  address: string;
  taluka: number;
}) {
  const response = await fetch(`${baseUrl}/auth/register/`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  const data = await handleResponse(response);
  storeTokens(data);
  return data;
}

export async function login(whatsappNumber: string, otpCode: string) {
  const response = await fetch(`${baseUrl}/auth/login/`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ whatsapp_number: whatsappNumber, otp_code: otpCode }),
  });
  const data = await handleResponse(response);
  storeTokens(data);
  return data;
}

// ---------- LOCATION DROPDOWNS ----------

export async function getStates() {
  const response = await fetch(`${baseUrl}/states/`);
  return handleResponse(response);
}

export async function getDistricts(stateId: number) {
  const response = await fetch(`${baseUrl}/districts/?state=${stateId}`);
  return handleResponse(response);
}

export async function getTalukas(districtId: number) {
  const response = await fetch(`${baseUrl}/talukas/?district=${districtId}`);
  return handleResponse(response);
}

// ---------- AUTHENTICATED REQUESTS ----------

async function authHeaders(): Promise<Record<string, string>> {
  const token = getAccessToken();
  return {
    "Content-Type": "application/json",
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
  };
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
  localStorage.setItem("access_token", data.access);
  return true;
}

export class SessionExpiredError extends Error {}

async function authorizedRequest(
  request: (headers: Record<string, string>) => Promise<Response>
) {
  let response = await request(await authHeaders());
  if (response.status === 401) {
    const refreshed = await refreshAccessToken();
    if (!refreshed) {
      logout();
      throw new SessionExpiredError();
    }
    response = await request(await authHeaders());
  }
  return handleResponse(response);
}

export async function getMyDealerProfile() {
  const list = await authorizedRequest((headers) =>
    fetch(`${baseUrl}/dealers/`, { headers })
  );
  return list.length > 0 ? list[0] : null;
}

export async function getMyLicencesByCategory(categoryId: number) {
  return authorizedRequest((headers) =>
    fetch(`${baseUrl}/licences/?category=${categoryId}`, { headers })
  );
}

export async function getLicenceCategories() {
  const response = await fetch(`${baseUrl}/licence-categories/`);
  return handleResponse(response);
}

export async function getLicenceTypes(categoryId: number) {
  const response = await fetch(`${baseUrl}/licence-types/?category=${categoryId}`);
  return handleResponse(response);
}

export async function getFertilizerTypes() {
  const response = await fetch(`${baseUrl}/fertilizer-types/`);
  return handleResponse(response);
}

export async function getLicenceEntries(licenceId: number) {
  return authorizedRequest((headers) =>
    fetch(`${baseUrl}/licence-entries/?licence=${licenceId}`, { headers })
  );
}

export async function createLicence(payload: {
  dealer: number;
  licence_type: number;
  licence_number: string;
  issue_date: string;
  expiry_date?: string | null;
}) {
  return authorizedRequest((headers) =>
    fetch(`${baseUrl}/licences/`, {
      method: "POST",
      headers,
      body: JSON.stringify(payload),
    })
  );
}

export async function updateLicence(
  licenceId: number,
  payload: {
    licence_type: number;
    licence_number: string;
    issue_date: string;
    expiry_date?: string | null;
  }
) {
  return authorizedRequest((headers) =>
    fetch(`${baseUrl}/licences/${licenceId}/`, {
      method: "PATCH",
      headers,
      body: JSON.stringify(payload),
    })
  );
}

export async function deleteLicence(licenceId: number) {
  return authorizedRequest((headers) =>
    fetch(`${baseUrl}/licences/${licenceId}/`, {
      method: "DELETE",
      headers,
    })
  );
}

export async function createLicenceEntry(payload: {
  licence: number;
  source_type?: string;
  company_name: string;
  fertilizer_type?: number[];
  valid_upto: string;
}) {
  return authorizedRequest((headers) =>
    fetch(`${baseUrl}/licence-entries/`, {
      method: "POST",
      headers,
      body: JSON.stringify(payload),
    })
  );
}

export async function updateLicenceEntry(
  entryId: number,
  payload: {
    source_type?: string;
    company_name: string;
    fertilizer_type?: number[];
    valid_upto: string;
  }
) {
  return authorizedRequest((headers) =>
    fetch(`${baseUrl}/licence-entries/${entryId}/`, {
      method: "PATCH",
      headers,
      body: JSON.stringify(payload),
    })
  );
}

export async function deleteLicenceEntry(entryId: number) {
  return authorizedRequest((headers) =>
    fetch(`${baseUrl}/licence-entries/${entryId}/`, {
      method: "DELETE",
      headers,
    })
  );
}

export async function getMyNotifications() {
  return authorizedRequest((headers) =>
    fetch(`${baseUrl}/notifications/`, { headers })
  );
}
