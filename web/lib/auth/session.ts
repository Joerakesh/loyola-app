const TOKEN_KEY = "loyola.token";
const EXPIRES_KEY = "loyola.expiresAt";

export function saveSession(token: string, expiresAt: number): void {
  if (typeof window === "undefined") return;

  localStorage.setItem(TOKEN_KEY, token);
  localStorage.setItem(EXPIRES_KEY, String(expiresAt));
}

export function getToken(): string | null {
  if (typeof window === "undefined") return null;

  return localStorage.getItem(TOKEN_KEY);
}

export function getExpiresAt(): number | null {
  if (typeof window === "undefined") return null;

  const value = localStorage.getItem(EXPIRES_KEY);

  if (!value) return null;

  const expiresAt = Number(value);

  return Number.isFinite(expiresAt) ? expiresAt : null;
}

export function removeSession(): void {
  if (typeof window === "undefined") return;

  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(EXPIRES_KEY);
}
