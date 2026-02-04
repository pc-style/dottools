/**
 * HTTP Tool: post - Make HTTP POST request
 */

export interface Input {
  /** URL to post to */
  url: string;
  /** Request body (JSON object or string) */
  body?: unknown;
  /** Content type, defaults to application/json */
  contentType?: string;
  /** Request headers */
  headers?: Record<string, string>;
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
  /** Parsed JSON response (if applicable) */
  json?: unknown;
  /** Error message if failed */
  error?: string;
}

export default async function post(input: Input): Promise<Output> {
  const { url, body, contentType = "application/json", headers = {}, timeout = 30000 } = input;

  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), timeout);

    const requestBody = typeof body === "string" ? body : JSON.stringify(body);

    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": contentType,
        ...headers,
      },
      body: requestBody,
      signal: controller.signal,
    });

    clearTimeout(timeoutId);

    const responseBody = await response.text();

    // Convert headers to record
    const responseHeaders: Record<string, string> = {};
    response.headers.forEach((value, key) => {
      responseHeaders[key] = value;
    });

    // Try to parse as JSON
    let json: unknown | undefined;
    try {
      json = JSON.parse(responseBody);
    } catch {
      // Not JSON
    }

    return {
      success: response.ok,
      status: response.status,
      headers: responseHeaders,
      body: responseBody,
      json,
    };
  } catch (err) {
    const error = err instanceof Error ? err.message : String(err);
    return {
      success: false,
      status: 0,
      headers: {},
      body: "",
      error,
    };
  }
}
