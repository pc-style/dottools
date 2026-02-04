/**
 * HTTP Tool: download - Download file from URL
 */

export interface Input {
  /** URL to download from */
  url: string;
  /** Path where file should be saved */
  destination: string;
  /** Request headers */
  headers?: Record<string, string>;
  /** Timeout in milliseconds, defaults to 60000 */
  timeout?: number;
}

export interface Output {
  /** Whether the download was successful */
  success: boolean;
  /** Path where file was saved */
  path: string;
  /** Size of downloaded file in bytes */
  size: number;
  /** MIME type of downloaded file */
  contentType?: string;
  /** Error message if failed */
  error?: string;
}

export default async function download(input: Input): Promise<Output> {
  const { url, destination, headers = {}, timeout = 60000 } = input;

  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), timeout);

    const response = await fetch(url, {
      headers,
      signal: controller.signal,
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      return {
        success: false,
        path: destination,
        size: 0,
        error: `HTTP ${response.status}: ${response.statusText}`,
      };
    }

    // Get content as array buffer
    const data = await response.arrayBuffer();
    
    // Ensure parent directory exists
    const parentDir = destination.substring(0, destination.lastIndexOf("/")) || ".";
    await Deno.mkdir(parentDir, { recursive: true });

    // Write file
    await Deno.writeFile(destination, new Uint8Array(data));

    const contentType = response.headers.get("content-type") || undefined;

    return {
      success: true,
      path: destination,
      size: data.byteLength,
      contentType,
    };
  } catch (err) {
    const error = err instanceof Error ? err.message : String(err);
    return {
      success: false,
      path: destination,
      size: 0,
      error,
    };
  }
}
