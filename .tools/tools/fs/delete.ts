/**
 * FS Tool: delete - Delete files or directories
 */

export interface Input {
  /** Path to the file or directory to delete */
  path: string;
  /** Recursively delete directories, defaults to false */
  recursive?: boolean;
}

export interface Output {
  /** Whether the deletion was successful */
  success: boolean;
  /** Path that was deleted */
  path: string;
  /** Whether the path existed before deletion */
  existed: boolean;
  /** Error message if failed */
  error?: string;
}

export default async function deleteFn(input: Input): Promise<Output> {
  const { path, recursive = false } = input;
  
  try {
    // Check if exists
    let existed = false;
    try {
      await Deno.stat(path);
      existed = true;
    } catch {
      // Doesn't exist
    }
    
    if (!existed) {
      return {
        success: true,
        path,
        existed: false,
      };
    }
    
    // Remove file or directory
    await Deno.remove(path, { recursive });
    
    return {
      success: true,
      path,
      existed: true,
    };
  } catch (err) {
    const error = err instanceof Error ? err.message : String(err);
    return {
      success: false,
      path,
      existed: true,
      error,
    };
  }
}
