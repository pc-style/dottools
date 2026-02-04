/**
 * FS Tool: read - Read file contents
 */

export interface Input {
  /** Path to the file to read */
  path: string;
  /** Encoding to use (utf8 or base64), defaults to utf8 */
  encoding?: "utf8" | "base64";
}

export interface Output {
  /** File contents */
  content: string;
  /** File size in bytes */
  size: number;
  /** Whether the file exists */
  exists: boolean;
  /** Last modified timestamp */
  modified?: number;
}

export default async function read(input: Input): Promise<Output> {
  const { path, encoding = "utf8" } = input;
  
  try {
    // Check if file exists
    const fileInfo = await Deno.stat(path);
    
    if (!fileInfo.isFile) {
      return {
        content: "",
        size: 0,
        exists: false,
      };
    }
    
    // Read file
    let content: string;
    
    if (encoding === "base64") {
      const data = await Deno.readFile(path);
      content = btoa(String.fromCharCode(...data));
    } else {
      content = await Deno.readTextFile(path);
    }
    
    return {
      content,
      size: content.length,
      exists: true,
      modified: fileInfo.mtime?.getTime(),
    };
  } catch (err) {
    if (err instanceof Deno.errors.NotFound) {
      return {
        content: "",
        size: 0,
        exists: false,
      };
    }
    throw err;
  }
}
