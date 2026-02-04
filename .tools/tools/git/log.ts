/**
 * Git Tool: log - Get commit history
 */

export interface Commit {
  /** Commit hash */
  hash: string;
  /** Short hash */
  shortHash: string;
  /** Author name */
  author: string;
  /** Author email */
  email: string;
  /** Commit date */
  date: string;
  /** Commit message */
  message: string;
  /** Changed files (if --stat included) */
  files?: string[];
}

export interface Input {
  /** Path to the git repository, defaults to current directory */
  path?: string;
  /** Number of commits to show, defaults to 10 */
  limit?: number;
  /** File path to filter by */
  file?: string;
  /** Include file statistics */
  stat?: boolean;
  /** Format: oneline, short, full, defaults to short */
  format?: "oneline" | "short" | "full";
}

export interface Output {
  /** Whether the operation was successful */
  success: boolean;
  /** Array of commits */
  commits: Commit[];
  /** Total commit count (if available) */
  total?: number;
  /** Error message if failed */
  error?: string;
}

export default async function log(input: Input): Promise<Output> {
  const { path = Deno.cwd(), limit = 10, file, stat = false, format = "short" } = input;

  try {
    // Build git log command
    const args = ["-C", path, "log", `--max-count=${limit}`, "--pretty=format:%H|%h|%an|%ae|%ai|%s%n---COMMIT---"];
    
    if (stat) {
      args.push("--name-only");
    }
    
    if (file) {
      args.push("--", file);
    }

    const cmd = new Deno.Command("git", {
      args,
      stdout: "piped",
      stderr: "piped",
    });

    const result = await cmd.output();
    const output = new TextDecoder().decode(result.stdout);
    const error = new TextDecoder().decode(result.stderr);

    if (!result.success) {
      return {
        success: false,
        commits: [],
        error: error.trim(),
      };
    }

    // Parse commits
    const commits: Commit[] = [];
    const commitBlocks = output.split("---COMMIT---").filter(b => b.trim());
    
    for (const block of commitBlocks) {
      const lines = block.trim().split("\n");
      const [hash, shortHash, author, email, date, message] = lines[0].split("|");
      
      const files = lines.slice(1).filter(l => l.trim());
      
      commits.push({
        hash,
        shortHash,
        author,
        email,
        date,
        message,
        files: stat ? files : undefined,
      });
    }

    return {
      success: true,
      commits,
      total: commits.length,
    };
  } catch (err) {
    const error = err instanceof Error ? err.message : String(err);
    return {
      success: false,
      commits: [],
      error,
    };
  }
}
