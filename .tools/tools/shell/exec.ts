/**
 * Shell Tool: exec - Execute shell commands
 */

export interface Input {
  /** Command to execute */
  command: string;
  /** Arguments for the command */
  args?: string[];
  /** Working directory */
  cwd?: string;
  /** Environment variables */
  env?: Record<string, string>;
  /** Timeout in milliseconds, defaults to 60000 */
  timeout?: number;
  /** Maximum output size in bytes, defaults to 10MB */
  maxOutput?: number;
}

export interface Output {
  /** Whether the command succeeded */
  success: boolean;
  /** Exit code */
  code: number;
  /** Standard output */
  stdout: string;
  /** Standard error */
  stderr: string;
  /** Combined output */
  output: string;
  /** Execution time in milliseconds */
  executionTime: number;
  /** Error message if failed to spawn */
  error?: string;
}

export default async function exec(input: Input): Promise<Output> {
  const {
    command,
    args = [],
    cwd,
    env,
    timeout = 60000,
    maxOutput = 10 * 1024 * 1024, // 10MB
  } = input;

  const startTime = performance.now();

  try {
    const cmd = new Deno.Command(command, {
      args,
      cwd,
      env: env ? { ...Deno.env.toObject(), ...env } : undefined,
      stdout: "piped",
      stderr: "piped",
    });

    const process = cmd.spawn();

    // Set up timeout
    const timeoutId = setTimeout(() => {
      try {
        process.kill();
      } catch {
        // Process might already be dead
      }
    }, timeout);

    const result = await process.output();
    clearTimeout(timeoutId);

    const executionTime = Math.round(performance.now() - startTime);

    let stdout = new TextDecoder().decode(result.stdout);
    let stderr = new TextDecoder().decode(result.stderr);

    // Truncate if too large
    if (stdout.length > maxOutput) {
      stdout = stdout.substring(0, maxOutput) + "\n[truncated]";
    }
    if (stderr.length > maxOutput) {
      stderr = stderr.substring(0, maxOutput) + "\n[truncated]";
    }

    return {
      success: result.code === 0,
      code: result.code,
      stdout,
      stderr,
      output: stdout + (stderr ? "\n" + stderr : ""),
      executionTime,
    };
  } catch (err) {
    const executionTime = Math.round(performance.now() - startTime);
    const error = err instanceof Error ? err.message : String(err);

    return {
      success: false,
      code: -1,
      stdout: "",
      stderr: "",
      output: "",
      executionTime,
      error,
    };
  }
}
