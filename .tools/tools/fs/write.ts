/**
 * FS Tool: write - Write content to a file
 */

export interface Input {
  /** Path to the file to write */
  path: string;
  /** Content to write */
  content: string;
  /** Encoding to use (utf8 or base64), defaults to utf8 */
  encoding?: "utf8" | "base64";
  /** Whether to append instead of overwrite */
  append?: boolean;
}

export interface Output {
  /** Whether the write was successful */
  success: boolean;
  /** Path of the written file */
  path: string;
  /** Size of written content in bytes */
  size: number;
  /** Error message if failed */
  error?: string;
}

export default async function write(input: Input): Promise<Output> {
  const { path, content, encoding = "utf8", append = false } = input;
  
  try {
    // Ensure parent directory exists
    const parentDir = path.substring(0, path.lastIndexOf("/")) || ".";
    await Deno.mkdir(parentDir, { recursive: true });
    
    // Prepare content
    let data: Uint8Array | string;
    
    if (encoding === "base64") {
      data = Uint8Array.from(atob(content), c => c.charCodeAt(0));
    } else {
      data = content;
    }
    
    // Write file
    if (append) {
      if (data instanceof Uint8Array) {
        const existing = await Deno.readFile(path).catch(() => new Uint8Array(0));
        const combined = new Uint8Array(existing.length + data.length);
        combined.set(existing);
        combined.set(data, existing.length);
        await Deno.writeFile(path, combined);
      } else {
        await Deno.writeTextFile(path, data, { append: true });
      }
    } else {
      if (data instanceof Uint8Array) {
        await Deno.writeFile(path, data);
      } else {
        await Deno.writeTextFile(path, data);
      }
    }
    
    return {
      success: true,
      path,
      size: content.length,
    };
  } catch (err) {
    const error = err instanceof Error ? err.message : String(err);
    return {
      success: false,
      path,
      size: 0,
      error,
    };
  }
}
