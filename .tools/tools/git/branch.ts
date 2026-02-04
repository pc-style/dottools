/**
 * Git Tool: branch - Manage branches
 */

export interface Branch {
  /** Branch name */
  name: string;
  /** Whether this is the current branch */
  current: boolean;
  /** Remote tracking branch */
  remote?: string;
  /** Ahead count */
  ahead?: number;
  /** Behind count */
  behind?: number;
}

export interface Input {
  /** Path to the git repository, defaults to current directory */
  path?: string;
  /** List branches (no action if true) */
  list?: boolean;
  /** Create new branch with this name */
  create?: string;
  /** Branch to create from, defaults to current */
  from?: string;
  /** Switch to this branch */
  switch?: string;
  /** Delete this branch */
  delete?: string;
  /** Force delete */
  force?: boolean;
}

export interface Output {
  /** Whether the operation was successful */
  success: boolean;
  /** Current branch (if listing) */
  current?: string;
  /** List of branches (if listing) */
  branches?: Branch[];
  /** Error message if failed */
  error?: string;
}

export default async function branch(input: Input): Promise<Output> {
  const { path = Deno.cwd(), list = true, create, from, switch: switchTo, delete: deleteBranch, force = false } = input;

  try {
    // Handle create branch
    if (create) {
      const args = ["-C", path, "checkout", "-b", create];
      if (from) {
        args.push(from);
      }
      
      const cmd = new Deno.Command("git", {
        args,
        stdout: "null",
        stderr: "piped",
      });

      const result = await cmd.output();
      if (!result.success) {
        const error = new TextDecoder().decode(result.stderr);
        return { success: false, error: `Failed to create branch: ${error}` };
      }

      return { success: true };
    }

    // Handle switch branch
    if (switchTo) {
      const cmd = new Deno.Command("git", {
        args: ["-C", path, "checkout", switchTo],
        stdout: "null",
        stderr: "piped",
      });

      const result = await cmd.output();
      if (!result.success) {
        const error = new TextDecoder().decode(result.stderr);
        return { success: false, error: `Failed to switch branch: ${error}` };
      }

      return { success: true };
    }

    // Handle delete branch
    if (deleteBranch) {
      const args = ["-C", path, "branch", force ? "-D" : "-d", deleteBranch];
      
      const cmd = new Deno.Command("git", {
        args,
        stdout: "null",
        stderr: "piped",
      });

      const result = await cmd.output();
      if (!result.success) {
        const error = new TextDecoder().decode(result.stderr);
        return { success: false, error: `Failed to delete branch: ${error}` };
      }

      return { success: true };
    }

    // List branches
    const cmd = new Deno.Command("git", {
      args: ["-C", path, "branch", "-vv", "--format=%(HEAD)%(refname:short)|%(upstream:short)|%(upstream:track)"],
      stdout: "piped",
      stderr: "piped",
    });

    const result = await cmd.output();
    const output = new TextDecoder().decode(result.stdout);
    const error = new TextDecoder().decode(result.stderr);

    if (!result.success) {
      return { success: false, branches: [], error: error.trim() };
    }

    const branches: Branch[] = [];
    let current = "";

    for (const line of output.split("\n").filter(l => l.trim())) {
      const [nameInfo, remote, track] = line.split("|");
      const isCurrent = nameInfo.startsWith("*");
      const name = isCurrent ? nameInfo.slice(1) : nameInfo;
      
      if (isCurrent) {
        current = name;
      }

      // Parse ahead/behind from track string like "[ahead 2, behind 1]"
      let ahead = 0;
      let behind = 0;
      
      if (track) {
        const aheadMatch = track.match(/ahead (\d+)/);
        const behindMatch = track.match(/behind (\d+)/);
        if (aheadMatch) ahead = parseInt(aheadMatch[1]);
        if (behindMatch) behind = parseInt(behindMatch[1]);
      }

      branches.push({
        name,
        current: isCurrent,
        remote: remote || undefined,
        ahead: ahead || undefined,
        behind: behind || undefined,
      });
    }

    return {
      success: true,
      current,
      branches,
    };
  } catch (err) {
    const error = err instanceof Error ? err.message : String(err);
    return { success: false, branches: [], error };
  }
}
