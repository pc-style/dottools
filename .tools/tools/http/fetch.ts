/**
 * HTTP Tool: fetch - Make HTTP GET request
 */

export interface Input {
  /** URL to fetch */
  url: string;
  /** Request headers */
  headers?: Record<string, string>;
  /** Follow redirects, defaults to true */
  followRedirects?: boolean;
  /** Timeout in milliseconds, defaults to 30000 */
  timeout?: number;
}

export interface Output {
  /** Whether the request was successful */
  success: boolean;
  /** HTTP status code */
  status: number;
  /** Response headers */
  headers: Record<string, string>;
  /** Response body as text */
  body: string;
  /** Response body size in bytes */
  size: number;
  /** Error message if failed */
  error?: string;
}

export default async function fetch(input: Input): Promise<Output> {
  const { url, headers = {}, followRedirects = true, timeout = 30000 } = input;

  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), timeout);

    const response = await fetch(url, {
      method: "GET",
      headers,
      redirect: followRedirects ? "follow" : "manual",
      signal: controller.signal,
    });

    clearTimeout(timeoutId);

    const body = await response.text();

    // Convert headers to record
    const responseHeaders: Record<string, string> = {};
    response.headers.forEach((value, key) => {
      responseHeaders[key] = value;
    });

    return {
      success: response.ok,
      status: response.status,
      headers: responseHeaders,
      body,
      size: body.length,
    };
  } catch (err) {
    const error = err instanceof Error ? err.message : String(err);
    return {
      success: false,
      status: 0,
      headers: {},
      body: "",
      size: 0,
      error,
    };
  }
}
