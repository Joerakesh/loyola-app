import { apiFetch } from "./client";
import { getToken, saveSession, removeSession } from "../auth/session";

export interface User {
  id: string;
  googleId: string;
  email: string;
  name: string;
  avatarUrl?: string | null;

  registrationNumber?: string | null;
  erpLinked?: boolean;

  linkedEmails?: string[];
}

interface GoogleLoginResponse {
  status: "success";
  user: User;
  authentication: {
    token: string;
    tokenType: "Bearer";
    expiresAt: number;
  };
}

interface MeResponse {
  status: "success";
  user: User;
}

interface BindErpResponse {
  status: "success";
  user: User;
}

interface AuthResponse {
  status: "success";
  authentication: {
    token: string;
    tokenType: "Bearer";
    expiresAt: number;
  };
}

function authHeaders(): HeadersInit {
  const token = getToken();

  if (!token) {
    throw new Error("Not authenticated");
  }

  return {
    Authorization: `Bearer ${token}`,
  };
}

export async function loginWithGoogle(idToken: string): Promise<User> {
  const response = await apiFetch<GoogleLoginResponse>("/auth/google", {
    method: "POST",
    body: JSON.stringify({
      idToken,
    }),
  });

  saveSession(response.authentication.token, response.authentication.expiresAt);

  return response.user;
}

export async function getCurrentUser(): Promise<User> {
  const response = await apiFetch<MeResponse>("/auth/google/me", {
    headers: authHeaders(),
  });

  return response.user;
}

export async function refreshSession(): Promise<void> {
  const response = await apiFetch<AuthResponse>("/auth/refresh", {
    method: "POST",
    headers: authHeaders(),
  });

  saveSession(response.authentication.token, response.authentication.expiresAt);
}

export async function bindErp(
  registrationNumber: string,
  password: string,
  email?: string,
): Promise<User> {
  const response = await apiFetch<BindErpResponse>("/auth/bind-erp", {
    method: "POST",
    headers: authHeaders(),
    body: JSON.stringify({
      registrationNumber,
      password,
      ...(email ? { email } : {}),
    }),
  });

  return response.user;
}

export async function bindEmail(email: string): Promise<User> {
  const response = await apiFetch<BindErpResponse>("/auth/bind-email", {
    method: "POST",
    headers: authHeaders(),
    body: JSON.stringify({
      email,
    }),
  });

  return response.user;
}

export async function logout(): Promise<void> {
  try {
    await apiFetch("/auth/logout", {
      method: "POST",
      headers: authHeaders(),
    });
  } finally {
    removeSession();
  }
}
