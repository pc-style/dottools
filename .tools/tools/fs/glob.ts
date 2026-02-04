/**
 * FS Tool: glob - Find files matching a pattern
 */

import { glob as globFn } from "https://deno.land/std@0.220.0/path/glob.ts";

export interface Input {
  /** Glob pattern (e.g., "**/*.ts", "src/**/*.js") */
  pattern: string;
  /** Root directory to search from, defaults to current directory */
  root?: string;
  /** Whether to include dotfiles */
  dot?: boolean;
  /** Maximum depth to search */
  maxDepth?: number;
}

export interface Output {
  /** Array of matching file paths */
  files: string[];
  /** Number of matches */
  count: number;
  /** Root directory that was searched */
  root: string;
}

export default async function glob(input: Input): Promise<Output> {
  const { pattern, root = Deno.cwd(), dot = false, maxDepth = Infinity } = input;
  
  try {
    const files: string[] = [];
    
    for await (const entry of globFn(pattern, {
      cwd: root,
      dot,
      includeDirs: false,
      followSymlinks: false,
    })) {
      const relativePath = entry;
      const depth = relativePath.split("/").length;
      
      if (depth <= maxDepth) {
        files.push(relativePath);
      }
    }
    
    // Sort for consistent results
    files.sort();
    
    return {
      files,
      count: files.length,
      root,
    };
  } catch (err) {
    const error = err instanceof Error ? err.message : String(err);
    throw new Error(`Glob failed: ${error}`);
  }
}
