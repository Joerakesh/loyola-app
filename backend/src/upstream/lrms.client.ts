import axios from "axios";
import { wrapper } from "axios-cookiejar-support";
import { CookieJar } from "tough-cookie";
import * as cheerio from "cheerio";
import { LRMS_CONFIG } from "../config/lrms.js";

export interface LRMSSessionState {
  cookies: string;
  registrationNumber: string;
  createdAt: number;
}

export class LRMSClient {
  private readonly jar: CookieJar;
  private readonly client;

  constructor(existingJar?: CookieJar) {
    this.jar = existingJar ?? new CookieJar();

    const axiosClient = axios.create({
      baseURL: LRMS_CONFIG.baseUrl,
      withCredentials: true,
      timeout: 15000,
      headers: {
        "User-Agent": "Mozilla/5.0 (compatible; CollegeMobileApp/1.0)",
        Accept: "*/*",
      },
    });

    this.client = wrapper(axiosClient as any);

    (this.client.defaults as any).jar = this.jar;
  }
  async getLoginPage() {
    const response = await this.client.get("/");

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
          "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
          "X-Requested-With": "XMLHttpRequest",
        },
      },
    );

    return response.data;
  }

  async get<T = unknown>(url: string) {
    return this.client.get(url) as Promise<{
      data: T;
      status: number;
    }>;
  }

  async post<T = unknown>(url: string, data?: unknown) {
    return this.client.post(url, data) as Promise<{
      data: T;
      status: number;
    }>;
  }

  async exportSession(registrationNumber: string): Promise<LRMSSessionState> {
    const cookies = await this.jar.getCookieString(LRMS_CONFIG.baseUrl);

    if (!cookies) {
      throw new Error("Cannot export LRMS session: no cookies found");
    }

    return {
      cookies,
      registrationNumber,
      createdAt: Date.now(),
    };
  }

  static async fromSession(session: LRMSSessionState): Promise<LRMSClient> {
    const jar = new CookieJar();

    await jar.setCookie(session.cookies, LRMS_CONFIG.baseUrl);

    const client = new LRMSClient(jar);

    // The axios-cookiejar-support wrapper needs the jar
    // associated with the client instance.
    return client;
  }
}
