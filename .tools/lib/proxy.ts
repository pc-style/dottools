/**
 * Tool Proxy - Creates a proxy that routes tool calls to actual implementations
 * 
 * This creates the illusion that tools are in-memory functions, but they are
 * actually loaded and executed dynamically.
 */

import { loadTool } from "./loader.ts";

export type ProgressFn = (step: string, data?: Record<string, unknown>) => void;

export function createToolsProxy(progress: ProgressFn): Record<string, unknown> {
  const cache = new Map<string, unknown>();
  
  return new Proxy({} as Record<string, unknown>, {
    get(_, namespace: string) {
      if (cache.has(namespace)) {
        return cache.get(namespace);
      }
      
      const namespaceProxy = new Proxy({} as Record<string, unknown>, {
        get(_, method: string) {
          return async (input: unknown) => {
            try {
              const tool = await loadTool(namespace, method);
              return await tool(input);
            } catch (err) {
              const error = err instanceof Error ? err : new Error(String(err));
              throw new Error(
                `Tool call failed: ${namespace}.${method}(${JSON.stringify(input)})
                
Error: ${error.message}`
              );
            }
          };
        }
      });
      
      cache.set(namespace, namespaceProxy);
      return namespaceProxy;
    }
  });
}
