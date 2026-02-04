/**
 * Search Tool: grep - Search file contents with grep/ripgrep
 */

export interface Input {
  /** Pattern to search for */
  pattern: string;
  /** File or directory path to search in */
  path?: string;
  /** Search recursively in directories */
  recursive?: boolean;
  /** Case insensitive search */
  ignoreCase?: boolean;
  /** Use regular expressions */
  regex?: boolean;
  /** Maximum number of matches to return */
  maxResults?: number;
  /** File glob pattern to filter by */
  include?: string;
  /** File glob pattern to exclude */
  exclude?: string;
}

export interface Match {
  /** File path */
  file: string;
  /** Line number */
  line: number;
  /** Line content */
  content: string;
  /** Match column */
  column?: number;
}

export interface Output {
  /** Whether the search was successful */
  success: boolean;
  /** Array of matches */
  matches: Match[];
  /** Total number of matches */
  count: number;
  /** Error message if failed */
  error?: string;
}

export default async function grep(input: Input): Promise<Output> {
  const { pattern, path = Deno.cwd(), recursive = true, ignoreCase = false, regex = true, maxResults = 100, include, exclude } = input;

  try {
    // Try ripgrep first (faster)
    const useRipgrep = await checkCommand("rg");
    
    let matches: Match[] = [];
    
    if (useRipgrep) {
      matches = await searchWithRipgrep(pattern, path, recursive, ignoreCase, regex, maxResults, include, exclude);
    } else {
      matches = await searchWithGrep(pattern, path, recursive, ignoreCase, regex, maxResults, include, exclude);
    }

    return {
      success: true,
      matches,
      count: matches.length,
    };
  } catch (err) {
    const error = err instanceof Error ? err.message : String(err);
    return {
      success: false,
      matches: [],
      count: 0,
      error,
    };
  }
}

async function checkCommand(cmd: string): Promise<boolean> {
  try {
    const command = new Deno.Command("which", {
      args: [cmd],
      stdout: "null",
      stderr: "null",
    });
    const result = await command.output();
    return result.success;
  } catch {
    return false;
  }
}

async function searchWithRipgrep(
  pattern: string,
  searchPath: string,
  recursive: boolean,
  ignoreCase: boolean,
  regex: boolean,
  maxResults: number,
  include?: string,
  exclude?: string
): Promise<Match[]> {
  const args = ["--line-number", "--column", "--json"];
  
  if (ignoreCase) args.push("--ignore-case");
  if (!regex) args.push("--fixed-strings");
  if (!recursive) args.push("--max-depth", "1");
  if (include) args.push("--glob", include);
  if (exclude) args.push("--glob", `!${exclude}`);
  
  args.push(pattern);
  
  // Check if path is a file or directory
  try {
    const info = await Deno.stat(searchPath);
    if (info.isFile) {
      args.push(searchPath);
    } else {
      args.push(searchPath);
    }
  } catch {
    args.push(searchPath);
  }

  const cmd = new Deno.Command("rg", { args, stdout: "piped", stderr: "piped" });
  const result = await cmd.output();
  
  const output = new TextDecoder().decode(result.stdout);
  const matches: Match[] = [];
  
  for (const line of output.split("\n").filter(l => l.trim())) {
    try {
      const data = JSON.parse(line);
      if (data.type === "match" && data.data) {
        const m = data.data;
        for (const submatch of m.submatches || []) {
          matches.push({
            file: m.path?.text || searchPath,
            line: m.line_number || 0,
            content: m.lines?.text?.trim() || "",
            column: submatch.start + 1,
          });
          
          if (matches.length >= maxResults) break;
        }
      }
    } catch {
      // Skip invalid lines
    }
    
    if (matches.length >= maxResults) break;
  }
  
  return matches;
}

async function searchWithGrep(
  pattern: string,
  searchPath: string,
  recursive: boolean,
  ignoreCase: boolean,
  regex: boolean,
  maxResults: number,
  include?: string,
  exclude?: string
): Promise<Match[]> {
  const matches: Match[] = [];
  
  try {
    const info = await Deno.stat(searchPath);
    
    if (info.isFile) {
      // Search single file
      const content = await Deno.readTextFile(searchPath);
      const fileMatches = searchInContent(content, pattern, searchPath, ignoreCase, regex, maxResults);
      matches.push(...fileMatches);
    } else if (info.isDirectory && recursive) {
      // Recursively search directory
      for await (const entry of Deno.readDir(searchPath)) {
        if (!entry.isFile) continue;
        
        // Apply include/exclude patterns
        if (include && !matchGlob(entry.name, include)) continue;
        if (exclude && matchGlob(entry.name, exclude)) continue;
        
        const filePath = `${searchPath}/${entry.name}`;
        try {
          const content = await Deno.readTextFile(filePath);
          const fileMatches = searchInContent(content, pattern, filePath, ignoreCase, regex, maxResults - matches.length);
          matches.push(...fileMatches);
          
          if (matches.length >= maxResults) break;
        } catch {
          // Skip files we can't read
        }
      }
    }
  } catch {
    // Path doesn't exist
  }
  
  return matches;
}

function searchInContent(
  content: string,
  pattern: string,
  filePath: string,
  ignoreCase: boolean,
  regex: boolean,
  maxResults: number
): Match[] {
  const matches: Match[] = [];
  const lines = content.split("\n");
  
  let searchPattern: RegExp;
  
  if (regex) {
    const flags = ignoreCase ? "gi" : "g";
    searchPattern = new RegExp(pattern, flags);
  } else {
    const escaped = pattern.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const flags = ignoreCase ? "gi" : "g";
    searchPattern = new RegExp(escaped, flags);
  }
  
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    let match: RegExpExecArray | null;
    
    // Reset lastIndex for global regex
    searchPattern.lastIndex = 0;
    
    while ((match = searchPattern.exec(line)) !== null) {
      matches.push({
        file: filePath,
        line: i + 1,
        content: line.trim(),
        column: match.index + 1,
      });
      
      if (matches.length >= maxResults) return matches;
      
      // Avoid infinite loop on zero-length matches
      if (match[0].length === 0) break;
    }
  }
  
  return matches;
}

function matchGlob(filename: string, pattern: string): boolean {
  // Simple glob matching
  const regex = new RegExp(
    "^" + pattern.replace(/\./g, "\\.").replace(/\*/g, ".*").replace(/\?/g, ".") + "$"
  );
  return regex.test(filename);
}
