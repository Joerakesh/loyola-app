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
  private cookies = "";

  constructor(cookies = "") {
    this.cookies = cookies;

    this.client = axios.create({
      baseURL: LRMS_CONFIG.baseUrl,
      timeout: 15000,
      headers: {
        "User-Agent": "Mozilla/5.0 (compatible; CollegeMobileApp/1.0)",
        Accept: "*/*",
      },
    });
  }

  private getHeaders() {
    return this.cookies
      ? {
          Cookie: this.cookies,
        }
      : {};
  }

  private updateCookies(response: {
    headers: {
      "set-cookie"?: string[];
    };
  }) {
    const setCookie = response.headers["set-cookie"];

    if (!setCookie) {
      return;
    }

    const newCookies = setCookie
      .map((cookie) => cookie.split(";")[0])
      .join("; ");

    if (newCookies) {
      this.cookies = newCookies;
    }
  }

  async getLoginPage() {
    const response = await this.client.get("/", {
      headers: this.getHeaders(),
    });

    this.updateCookies(response);

    const $ = cheerio.load(response.data);

    const captcha = $(".captcha__text").first().text().trim();

    if (!captcha) {
      throw new Error("CAPTCHA not found in LRMS login page");
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
          ...this.getHeaders(),
          "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
          "X-Requested-With": "XMLHttpRequest",
        },
      },
    );

    this.updateCookies(response);

    return response.data;
  }

  async get<T = unknown>(url: string) {
    const response = await this.client.get<T>(url, {
      headers: this.getHeaders(),
    });

    this.updateCookies(response);

    return response;
  }

  async post<T = unknown>(url: string, data?: unknown) {
    const response = await this.client.post<T>(url, data, {
      headers: this.getHeaders(),
    });

    this.updateCookies(response);

    return response;
  }

  async exportSession(registrationNumber: string): Promise<LRMSSessionState> {
    if (!this.cookies) {
      throw new Error("Cannot export LRMS session: no cookies found");
    }

    return {
      cookies: this.cookies,
      registrationNumber,
      createdAt: Date.now(),
    };
  }

  static fromSession(session: LRMSSessionState): LRMSClient {
    return new LRMSClient(session.cookies);
  }
}
