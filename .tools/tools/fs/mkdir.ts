/**
 * FS Tool: mkdir - Create directories
 */

export interface Input {
  /** Path to the directory to create */
  path: string;
  /** Create parent directories if they don't exist, defaults to true */
  recursive?: boolean;
}

export interface Output {
  /** Whether the directory was created successfully */
  success: boolean;
  /** Path of the created directory */
  path: string;
  /** Whether the directory already existed */
  existed: boolean;
  /** Error message if failed */
  error?: string;
}

export default async function mkdir(input: Input): Promise<Output> {
  const { path, recursive = true } = input;
  
  try {
    // Check if already exists
    try {
      const info = await Deno.stat(path);
      if (info.isDirectory) {
        return {
          success: true,
          path,
          existed: true,
        };
      } else {
        return {
          success: false,
          path,
          existed: false,
          error: `Path exists but is not a directory: ${path}`,
        };
      }
    } catch {
      // Doesn't exist, proceed to create
    }
    
    await Deno.mkdir(path, { recursive });
    
    return {
      success: true,
      path,
      existed: false,
    };
  } catch (err) {
    const error = err instanceof Error ? err.message : String(err);
    return {
      success: false,
      path,
      existed: false,
      error,
    };
  }
}
