/**
 * Git Tool: status - Get git repository status
 */

export interface Input {
  /** Path to the git repository, defaults to current directory */
  path?: string;
}

export interface Output {
  /** Whether this is a git repository */
  isRepo: boolean;
  /** Current branch name */
  branch: string;
  /** Whether working tree is clean */
  isClean: boolean;
  /** Array of modified files */
  modified: string[];
  /** Array of untracked files */
  untracked: string[];
  /** Array of staged files */
  staged: string[];
  /** Array of deleted files */
  deleted: string[];
  /** Array of renamed files */
  renamed: { old: string; new: string }[];
  /** Number of commits ahead of remote */
  ahead?: number;
  /** Number of commits behind remote */
  behind?: number;
  /** Error message if not a repo */
  error?: string;
}

export default async function status(input: Input): Promise<Output> {
  const { path = Deno.cwd() } = input;
  
  try {
    // Check if git repo
    const checkCmd = new Deno.Command("git", {
      args: ["-C", path, "rev-parse", "--git-dir"],
      stdout: "null",
      stderr: "null",
    });
    
    const check = await checkCmd.output();
    if (!check.success) {
      return {
        isRepo: false,
        branch: "",
        isClean: true,
        modified: [],
        untracked: [],
        staged: [],
        deleted: [],
        renamed: [],
        error: "Not a git repository",
      };
    }
    
    // Get current branch
    const branchCmd = new Deno.Command("git", {
      args: ["-C", path, "branch", "--show-current"],
      stdout: "piped",
      stderr: "null",
    });
    
    const branchResult = await branchCmd.output();
    const branch = new TextDecoder().decode(branchResult.stdout).trim() || "HEAD";
    
    // Get status in porcelain format
    const statusCmd = new Deno.Command("git", {
      args: ["-C", path, "status", "--porcelain", "-b", "--porcelain=v2"],
      stdout: "piped",
      stderr: "null",
    });
    
    const statusResult = await statusCmd.output();
    const statusText = new TextDecoder().decode(statusResult.stdout);
    
    const modified: string[] = [];
    const untracked: string[] = [];
    const staged: string[] = [];
    const deleted: string[] = [];
    const renamed: { old: string; new: string }[] = [];
    let ahead: number | undefined;
    let behind: number | undefined;
    
    const lines = statusText.split("\n");
    
    for (const line of lines) {
      if (line.startsWith("# branch.ab ")) {
        // Parse ahead/behind
        const parts = line.split(" ");
        ahead = parseInt(parts[2]) || 0;
        behind = parseInt(parts[3]) || 0;
      } else if (line.length >= 2) {
        const xy = line.substring(0, 2);
        const rest = line.substring(3);
        
        // XY format: X=staged, Y=unstaged
        // ? = untracked, M = modified, A = added, D = deleted, R = renamed
        
        if (xy === "??") {
          untracked.push(rest);
        } else {
          // Check staged changes (X)
          if (xy[0] === "M" || xy[0] === "A") {
            staged.push(rest);
          } else if (xy[0] === "D") {
            staged.push(rest);
          } else if (xy[0] === "R") {
            const parts = rest.split(" ");
            renamed.push({ old: parts[0], new: parts[1] });
          }
          
          // Check unstaged changes (Y)
          if (xy[1] === "M") {
            modified.push(rest);
          } else if (xy[1] === "D") {
            deleted.push(rest);
          }
        }
      }
    }
    
    const isClean = modified.length === 0 && 
                    untracked.length === 0 && 
                    staged.length === 0 && 
                    deleted.length === 0 &&
                    renamed.length === 0;
    
    return {
      isRepo: true,
      branch,
      isClean,
      modified,
      untracked,
      staged,
      deleted,
      renamed,
      ahead,
      behind,
    };
  } catch (err) {
    const error = err instanceof Error ? err.message : String(err);
    return {
      isRepo: false,
      branch: "",
      isClean: true,
      modified: [],
      untracked: [],
      staged: [],
      deleted: [],
      renamed: [],
      error,
    };
  }
}
