/**
 * Git Tool: diff - Get diff between commits or working tree
 */

export interface Input {
  /** Path to the git repository, defaults to current directory */
  path?: string;
  /** First commit (or "HEAD" for working tree), defaults to "HEAD" */
  from?: string;
  /** Second commit, omit to compare against working tree */
  to?: string;
  /** File path to filter diff by */
  file?: string;
}

export interface Output {
  /** Whether the diff was successful */
  success: boolean;
  /** Diff output as string */
  diff: string;
  /** Whether there are changes */
  hasChanges: boolean;
  /** Number of files changed */
  filesChanged: number;
  /** Error message if failed */
  error?: string;
}

export default async function diff(input: Input): Promise<Output> {
  const { path = Deno.cwd(), from = "HEAD", to, file } = input;

  try {
    // Build git diff command
    const args = ["-C", path, "diff"];
    
    if (to) {
      args.push(`${from}..${to}`);
    } else if (from !== "WORKING") {
      args.push(from);
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
    const diffText = new TextDecoder().decode(result.stdout);
    const errorText = new TextDecoder().decode(result.stderr);

    if (!result.success && errorText) {
      return {
        success: false,
        diff: "",
        hasChanges: false,
        filesChanged: 0,
        error: errorText.trim(),
      };
    }

    // Count files changed (diff --stat would be better but this is simpler)
    const hasChanges = diffText.trim().length > 0;
    const filesChanged = hasChanges 
      ? (diffText.match(/^diff --git/gm)?.length || 0)
      : 0;

    return {
      success: true,
      diff: diffText,
      hasChanges,
      filesChanged,
    };
  } catch (err) {
    const error = err instanceof Error ? err.message : String(err);
    return {
      success: false,
      diff: "",
      hasChanges: false,
      filesChanged: 0,
      error,
    };
  }
}
