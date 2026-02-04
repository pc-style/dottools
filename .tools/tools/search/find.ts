/**
 * Search Tool: find - Find files by name or pattern
 */

export interface Input {
  /** Root directory to search from */
  path?: string;
  /** File name pattern (glob) */
  name?: string;
  /** Search pattern in file names */
  pattern?: string;
  /** File type: f=file, d=directory */
  type?: "f" | "d";
  /** Maximum depth to search */
  maxDepth?: number;
  /** Minimum file size in bytes */
  minSize?: number;
  /** Maximum file size in bytes */
  maxSize?: number;
  /** Modified after this timestamp (epoch ms) */
  modifiedAfter?: number;
  /** Modified before this timestamp (epoch ms) */
  modifiedBefore?: number;
}

export interface FileInfo {
  /** File path */
  path: string;
  /** File name */
  name: string;
  /** File size in bytes */
  size: number;
  /** Is directory */
  isDirectory: boolean;
  /** Last modified timestamp */
  modified: number;
}

export interface Output {
  /** Whether the search was successful */
  success: boolean;
  /** Array of matching files */
  files: FileInfo[];
  /** Total count */
  count: number;
  /** Error message if failed */
  error?: string;
}

export default async function find(input: Input): Promise<Output> {
  const {
    path = Deno.cwd(),
    name,
    pattern,
    type,
    maxDepth = Infinity,
    minSize,
    maxSize,
    modifiedAfter,
    modifiedBefore,
  } = input;

  try {
    const files: FileInfo[] = [];
    
    await searchDirectory(
      path,
      "",
      0,
      maxDepth,
      { name, pattern, type, minSize, maxSize, modifiedAfter, modifiedBefore },
      files
    );

    // Sort by path
    files.sort((a, b) => a.path.localeCompare(b.path));

    return {
      success: true,
      files,
      count: files.length,
    };
  } catch (err) {
    const error = err instanceof Error ? err.message : String(err);
    return {
      success: false,
      files: [],
      count: 0,
      error,
    };
  }
}

async function searchDirectory(
  root: string,
  relativePath: string,
  depth: number,
  maxDepth: number,
  filters: {
    name?: string;
    pattern?: string;
    type?: "f" | "d";
    minSize?: number;
    maxSize?: number;
    modifiedAfter?: number;
    modifiedBefore?: number;
  },
  results: FileInfo[]
): Promise<void> {
  if (depth > maxDepth) return;

  const currentPath = relativePath ? `${root}/${relativePath}` : root;

  try {
    for await (const entry of Deno.readDir(currentPath)) {
      const entryRelativePath = relativePath ? `${relativePath}/${entry.name}` : entry.name;
      const fullPath = `${root}/${entryRelativePath}`;

      const isDirectory = entry.isDirectory;

      // Check type filter
      if (filters.type) {
        if (filters.type === "f" && isDirectory) continue;
        if (filters.type === "d" && !isDirectory) continue;
      }

      // Check name filter (glob)
      if (filters.name && !matchGlob(entry.name, filters.name)) {
        continue;
      }

      // Check pattern filter (regex)
      if (filters.pattern && !new RegExp(filters.pattern).test(entry.name)) {
        continue;
      }

      // Get file info for size/modified filters
      let fileInfo: Deno.FileInfo | null = null;
      
      if (filters.minSize !== undefined || filters.maxSize !== undefined || 
          filters.modifiedAfter !== undefined || filters.modifiedBefore !== undefined) {
        try {
          fileInfo = await Deno.stat(fullPath);
        } catch {
          continue;
        }

        // Check size filters
        if (filters.minSize !== undefined && fileInfo.size < filters.minSize) continue;
        if (filters.maxSize !== undefined && fileInfo.size > filters.maxSize) continue;

        // Check modified filters
        const modified = fileInfo.mtime?.getTime() || 0;
        if (filters.modifiedAfter !== undefined && modified < filters.modifiedAfter) continue;
        if (filters.modifiedBefore !== undefined && modified > filters.modifiedBefore) continue;
      }

      // Add to results
      results.push({
        path: fullPath,
        name: entry.name,
        size: fileInfo?.size || 0,
        isDirectory,
        modified: fileInfo?.mtime?.getTime() || 0,
      });

      // Recurse into directories
      if (isDirectory && depth < maxDepth) {
        await searchDirectory(root, entryRelativePath, depth + 1, maxDepth, filters, results);
      }
    }
  } catch {
    // Directory might not be readable
  }
}

function matchGlob(filename: string, pattern: string): boolean {
  const regex = new RegExp(
    "^" + pattern
      .replace(/\./g, "\\.")
      .replace(/\*\*/g, "{{GLOBSTAR}}")
      .replace(/\*/g, "[^/]*")
      .replace(/\?/g, ".")
      .replace(/{{GLOBSTAR}}/g, ".*") + "$"
  );
  return regex.test(filename);
}
