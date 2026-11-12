// The Next.js frontend is deployed separately from the Express API project.
const API_URL =
  process.env.NEXT_PUBLIC_API_URL?.replace(/\/+$/, "") ||
  "https://loyola-app-livid.vercel.app/api/v1";

export class ApiError extends Error {
  status: number;

  constructor(message: string, status: number) {
    super(message);
    this.name = "ApiError";
    this.status = status;
  }
}

export async function apiFetch<T>(
  endpoint: string,
  options: RequestInit = {},
): Promise<T> {
  const isV2 = endpoint.startsWith("/v2/");
  const apiBase = isV2 ? API_URL.replace(/\/v\d+$/, "/v2") : API_URL;
  const apiPath = isV2 ? endpoint.slice(3) : endpoint;
  const url = `${apiBase}${apiPath}`;
  let response: Response;

  try {
    response = await fetch(url, {
      ...options,
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
        ...options.headers,
      },
    });
  } catch (error) {
    console.error("[API] Network request failed", {
      method: options.method ?? "GET",
      url,
      error,
    });
    throw error;
  }

  let body: unknown;

  try {
    body = await response.json();
  } catch {
    body = null;
  }

  if (!response.ok) {
    const message =
      typeof body === "object" &&
      body !== null &&
      "message" in body &&
      typeof body.message === "string"
        ? body.message
        : "Request failed";

    console.error("[API] Request returned an error", {
      method: options.method ?? "GET",
      url,
      status: response.status,
      statusText: response.statusText,
      body,
    });

    throw new ApiError(message, response.status);
  }

  return body as T;
}
