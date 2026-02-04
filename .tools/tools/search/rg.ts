/**
 * Search Tool: rg - Use ripgrep for fast searching
 * This is a wrapper around the system's ripgrep command
 */

export interface Input {
  /** Pattern to search for */
  pattern: string;
  /** Directory or file to search */
  path?: string;
  /** File glob pattern */
  glob?: string;
  /** Search case insensitively */
  ignoreCase?: boolean;
  /** Use fixed strings (no regex) */
  fixedStrings?: boolean;
  /** Maximum number of results */
  maxResults?: number;
  /** Show line numbers */
  lineNumbers?: boolean;
  /** Include file type filter (e.g., "ts", "js", "md") */
  type?: string;
}

export interface Match {
  /** File path */
  file: string;
  /** Line number */
  line: number;
  /** Column number */
  column?: number;
  /** Matched content */
  content: string;
}

export interface Output {
  /** Whether the search was successful */
  success: boolean;
  /** Array of matches */
  matches: Match[];
  /** Total match count */
  count: number;
  /** Error message if failed */
  error?: string;
}

export default async function rg(input: Input): Promise<Output> {
  const {
    pattern,
    path = Deno.cwd(),
    glob,
    ignoreCase = false,
    fixedStrings = false,
    maxResults = 100,
    lineNumbers = true,
    type,
  } = input;

  try {
    // Build rg command arguments
    const args: string[] = [
      "--json", // Output in JSON format
      "--line-number",
      "--column",
    ];

    if (ignoreCase) args.push("--ignore-case");
    if (fixedStrings) args.push("--fixed-strings");
    if (glob) args.push("--glob", glob);
    if (type) args.push("--type", type);

    // Add max results
    args.push("--max-count", maxResults.toString());

    // Add pattern and path
    args.push(pattern, path);

    // Execute ripgrep
    const cmd = new Deno.Command("rg", {
      args,
      stdout: "piped",
      stderr: "piped",
    });

    const result = await cmd.output();
    const stdout = new TextDecoder().decode(result.stdout);
    const stderr = new TextDecoder().decode(result.stderr);

    // rg exits with code 1 when no matches found, which is not an error
    if (!result.success && result.code !== 1) {
      return {
        success: false,
        matches: [],
        count: 0,
        error: stderr.trim() || `ripgrep exited with code ${result.code}`,
      };
    }

    // Parse JSON output
    const matches: Match[] = [];

    for (const line of stdout.split("\n").filter((l) => l.trim())) {
      try {
        const data = JSON.parse(line);

        if (data.type === "match" && data.data) {
          const matchData = data.data;
          const filePath = matchData.path?.text || matchData.path || path;

          for (const submatch of matchData.submatches || []) {
            matches.push({
              file: filePath,
              line: matchData.line_number || 0,
              column: submatch.start + 1,
              content: matchData.lines?.text?.trim() || "",
            });
          }
        }
      } catch {
        // Skip invalid JSON lines
      }
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
      error: `Failed to execute ripgrep: ${error}`,
    };
  }
}
