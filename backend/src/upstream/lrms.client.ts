import axios from "axios";
import * as cheerio from "cheerio";
import { LRMS_CONFIG } from "../config/lrms.js";

export interface LRMSSessionState {
  cookies: string;
  registrationNumber: string;
  createdAt: number;
}

export class LRMSClient {
  private readonly client;
  private readonly origin: string;
  private readonly loginReferer: string;
  private readonly dashboardReferer: string;
  private readonly cookies = new Map<string, string>();

  constructor(cookieHeader = "") {
    const baseUrl = LRMS_CONFIG.baseUrl.replace(/\/+$/, "");
    this.origin = new URL(baseUrl).origin;
    this.loginReferer = baseUrl + "/";
    this.dashboardReferer = baseUrl + "/dashboard.jsp";

    this.client = axios.create({
      baseURL: baseUrl + "/",
      timeout: 20000,
      headers: {
        "User-Agent":
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/156.0.0.0 Safari/537.36",
      },
    });

    this.mergeCookieHeader(cookieHeader);
  }

  private getCookieHeader() {
    return [...this.cookies.entries()]
      .map(([name, value]) => name + "=" + value)
      .join("; ");
  }

  private getCookieHeaders() {
    const cookie = this.getCookieHeader();
    return cookie ? { Cookie: cookie } : {};
  }

  private getAjaxHeaders(referer = this.dashboardReferer) {
    return {
      ...this.getCookieHeaders(),
      Accept: "application/json, text/javascript, */*; q=0.01",
      Origin: this.origin,
      Referer: referer,
      "X-Requested-With": "XMLHttpRequest",
    };
  }

  private mergeCookieHeader(cookieHeader: string) {
    for (const pair of cookieHeader.split(";")) {
      const separator = pair.indexOf("=");
      if (separator <= 0) continue;
      const name = pair.slice(0, separator).trim();
      const value = pair.slice(separator + 1).trim();
      if (name) this.cookies.set(name, value);
    }
  }

  private updateCookies(response: {
    headers: {
      "set-cookie"?: string[];
    };
  }) {
    for (const setCookie of response.headers["set-cookie"] ?? []) {
      const pair = setCookie.split(";", 1)[0];
      this.mergeCookieHeader(pair);
    }
  }

  async getLoginPage() {
    const response = await this.client.get("/", {
      headers: {
        ...this.getCookieHeaders(),
        Accept:
          "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
      },
    });

    this.updateCookies(response);

    const $ = cheerio.load(response.data);
    const captcha = $(".captcha__text").first().text().trim();

    if (!captcha) {
      throw new Error(
        "CAPTCHA not found in LRMS login page (HTTP " + response.status + ")",
      );
    }

    return {
      captcha,
      statusCode: response.status,
    };
  }

  async login(registrationNumber: string, password: string, captcha: string) {
    const body = new URLSearchParams();
    body.append("registerno", registrationNumber);
    body.append("password", password);
    body.append("captcha", captcha);

    const response = await this.client.post(
      LRMS_CONFIG.endpoints.login,
      body.toString(),
      {
        headers: {
          ...this.getAjaxHeaders(this.loginReferer),
          "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
        },
      },
    );

    this.updateCookies(response);
    return response.data;
  }

  async get<T = unknown>(url: string) {
    const response = await this.client.get<T>(url, {
      headers: this.getAjaxHeaders(),
    });

    this.updateCookies(response);
    return response;
  }

  async post<T = unknown>(url: string, data?: unknown) {
    const response = await this.client.post<T>(url, data, {
      headers: this.getAjaxHeaders(),
    });

    this.updateCookies(response);
    return response;
  }

  async exportSession(registrationNumber: string): Promise<LRMSSessionState> {
    return {
      cookies: this.getCookieHeader(),
      registrationNumber,
      createdAt: Date.now(),
    };
  }

  static fromSession(session: LRMSSessionState): LRMSClient {
    return new LRMSClient(session.cookies);
  }
}
