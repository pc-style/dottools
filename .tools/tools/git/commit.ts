/**
 * Git Tool: commit - Create a git commit
 */

export interface Input {
  /** Path to the git repository, defaults to current directory */
  path?: string;
  /** Commit message */
  message: string;
  /** Whether to stage all changes before committing, defaults to false */
  all?: boolean;
  /** Files to commit (if not committing all) */
  files?: string[];
}

export interface Output {
  /** Whether the commit was successful */
  success: boolean;
  /** Commit hash (if successful) */
  hash?: string;
  /** Error message if failed */
  error?: string;
}

export default async function commit(input: Input): Promise<Output> {
  const { path = Deno.cwd(), message, all = false, files = [] } = input;

  try {
    // Stage files if needed
    if (all) {
      const stageCmd = new Deno.Command("git", {
        args: ["-C", path, "add", "-A"],
        stdout: "null",
        stderr: "piped",
      });
      const stageResult = await stageCmd.output();
      if (!stageResult.success) {
        const error = new TextDecoder().decode(stageResult.stderr);
        return { success: false, error: `Failed to stage files: ${error}` };
      }
    } else if (files.length > 0) {
      const stageCmd = new Deno.Command("git", {
        args: ["-C", path, "add", ...files],
        stdout: "null",
        stderr: "piped",
      });
      const stageResult = await stageCmd.output();
      if (!stageResult.success) {
        const error = new TextDecoder().decode(stageResult.stderr);
        return { success: false, error: `Failed to stage files: ${error}` };
      }
    }

    // Create commit
    const commitCmd = new Deno.Command("git", {
      args: ["-C", path, "commit", "-m", message],
      stdout: "piped",
      stderr: "piped",
    });

    const result = await commitCmd.output();
    const output = new TextDecoder().decode(result.stdout);
    const error = new TextDecoder().decode(result.stderr);

    if (!result.success) {
      return {
        success: false,
        error: error.trim() || "Commit failed",
      };
    }

    // Extract commit hash
    const hashMatch = output.match(/\[.+?\s+([a-f0-9]+)\]/);
    const hash = hashMatch ? hashMatch[1] : undefined;

    return {
      success: true,
      hash,
    };
  } catch (err) {
    const error = err instanceof Error ? err.message : String(err);
    return { success: false, error };
  }
}
