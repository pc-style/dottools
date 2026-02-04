/**
 * Tool Loader - Dynamically loads tool implementations
 */

import { path } from "https://deno.land/std@0.220.0/path/mod.ts";

const __dirname = path.dirname(path.fromFileUrl(import.meta.url));
const TOOLS_DIR = path.join(__dirname, "..", "tools");

export interface ToolFunction {
  (input: unknown): Promise<unknown>;
}

const toolCache = new Map<string, ToolFunction>();

export async function loadTool(
  namespace: string,
  method: string
): Promise<ToolFunction> {
  const cacheKey = `${namespace}.${method}`;
  
  if (toolCache.has(cacheKey)) {
    return toolCache.get(cacheKey)!;
  }
  
  const toolPath = path.join(TOOLS_DIR, namespace, `${method}.ts`);
  
  try {
    // Check if TypeScript implementation exists
    await Deno.stat(toolPath);
    
    // Dynamically import the tool
    const module = await import(toolPath);
    
    if (typeof module.default !== "function") {
      throw new Error(
        `Tool ${namespace}.${method} does not export a default function`
      );
    }
    
    toolCache.set(cacheKey, module.default);
    return module.default;
  } catch (err) {
    // If TypeScript version doesn't exist, check for shell fallback
    const shellPath = path.join(TOOLS_DIR, namespace, `${method}.sh`);
    
    try {
      await Deno.stat(shellPath);
      
      // Create wrapper function for shell tool
      const shellTool: ToolFunction = async (input: unknown) => {
        const cmd = new Deno.Command("bash", {
          args: [shellPath],
          stdin: "piped",
          stdout: "piped",
          stderr: "piped",
        });
        
        const process = cmd.spawn();
        
        // Send input as JSON
        const encoder = new TextEncoder();
        const writer = process.stdin.getWriter();
        await writer.write(encoder.encode(JSON.stringify(input)));
        writer.releaseLock();
        process.stdin.close();
        
        // Get output
        const output = await process.output();
        const decoder = new TextDecoder();
        const stdout = decoder.decode(output.stdout);
        const stderr = decoder.decode(output.stderr);
        
        if (output.code !== 0) {
          throw new Error(stderr || `Shell tool exited with code ${output.code}`);
        }
        
        // Try to parse as JSON, otherwise return as string
        try {
          return JSON.parse(stdout);
        } catch {
          return stdout.trim();
        }
      };
      
      toolCache.set(cacheKey, shellTool);
      return shellTool;
    } catch {
      throw new Error(
        `Tool not found: ${namespace}.${method} (tried ${toolPath} and ${shellPath})`
      );
    }
  }
}

export function clearToolCache(): void {
  toolCache.clear();
}

export function listAvailableTools(): string[] {
  const tools: string[] = [];
  
  for (const [key] of toolCache) {
    tools.push(key);
  }
  
  return tools;
}
