#!/usr/bin/env -S deno run --allow-all

/**
 * Programmatic Tool Calling (PTC) Executor - Deno Version
 * 
 * This executor enables AI agents to write and execute code that orchestrates
 * multiple tools in a single pass, reducing token usage and latency.
 * 
 * Usage:
 *   .tools/executor <<'CODE'
 *   const files = await tools.fs.glob({ pattern: "**/*.ts" });
 *   for (const file of files) {
 *     const content = await tools.fs.read({ path: file });
 *     console.log(file, content.length);
 *   }
 *   return files;
 *   CODE
 */

import { createToolsProxy } from "./lib/proxy.ts";
import { loadTool } from "./lib/loader.ts";

interface ExecutionResult {
  status: "success" | "error";
  output: unknown;
  error?: {
    message: string;
    stack?: string;
    type: string;
  };
  progressLogs: ProgressLog[];
  executionTime: number;
}

interface ProgressLog {
  step: string;
  data?: Record<string, unknown>;
  timestamp: number;
}

const progressLogs: ProgressLog[] = [];

function progress(step: string, data?: Record<string, unknown>) {
  const log: ProgressLog = {
    step,
    data,
    timestamp: Date.now(),
  };
  progressLogs.push(log);
  // Also output for real-time streaming
  console.error(JSON.stringify({ type: "progress", ...log }));
}

async function readStdin(): Promise<string> {
  const decoder = new TextDecoder();
  const chunks: Uint8Array[] = [];
  
  for await (const chunk of Deno.stdin.readable) {
    chunks.push(chunk);
  }
  
  return decoder.decode(new Uint8Array(
    chunks.reduce((acc, chunk) => {
      const newAcc = new Uint8Array(acc.length + chunk.length);
      newAcc.set(acc);
      newAcc.set(chunk, acc.length);
      return newAcc;
    }, new Uint8Array(0))
  ));
}

async function executeCode(code: string): Promise<ExecutionResult> {
  const startTime = performance.now();
  
  // Create tools proxy that routes calls to actual tool implementations
  const tools = createToolsProxy(progress);
  
  // Wrap code in an async IIFE to support top-level await
  const wrappedCode = `
    (async () => {
      ${code}
    })()
  `;
  
  try {
    // Create a function with tools in scope
    const fn = new Function("tools", "progress", wrappedCode);
    const result = await fn(tools, progress);
    
    const executionTime = performance.now() - startTime;
    
    return {
      status: "success",
      output: result,
      progressLogs,
      executionTime,
    };
  } catch (err) {
    const executionTime = performance.now() - startTime;
    const error = err instanceof Error ? err : new Error(String(err));
    
    return {
      status: "error",
      output: null,
      error: {
        message: error.message,
        stack: error.stack,
        type: error.name,
      },
      progressLogs,
      executionTime,
    };
  }
}

async function main() {
  try {
    const code = await readStdin();
    
    if (!code.trim()) {
      console.log(JSON.stringify({
        status: "error",
        output: null,
        error: {
          message: "No code provided. Usage: .tools/executor <<'CODE' ... CODE",
          type: "NoInputError",
        },
        progressLogs: [],
        executionTime: 0,
      }));
      Deno.exit(1);
    }
    
    const result = await executeCode(code);
    console.log(JSON.stringify(result, null, 2));
    
    Deno.exit(result.status === "success" ? 0 : 1);
  } catch (err) {
    const error = err instanceof Error ? err : new Error(String(err));
    console.log(JSON.stringify({
      status: "error",
      output: null,
      error: {
        message: error.message,
        stack: error.stack,
        type: error.name,
      },
      progressLogs: [],
      executionTime: 0,
    }));
    Deno.exit(1);
  }
}

if (import.meta.main) {
  main();
}

export { executeCode, progress };
export type { ExecutionResult, ProgressLog };
