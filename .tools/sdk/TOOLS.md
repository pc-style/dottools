# PTC Tools Reference

Complete reference for all available tools in the Programmatic Tool Calling harness.

## Overview

This harness enables AI agents to execute code that orchestrates multiple tools in a single pass, reducing token usage and latency.

**Usage:**
```bash
.tools/executor <<'CODE'
// Your code here
CODE
```

## Available Tools

### fs (Filesystem)

Tools for file and directory operations.

#### `fs.read`
Read file contents.

**Input:**
```typescript
{
  path: string;          // Path to file
  encoding?: "utf8" | "base64";  // Default: "utf8"
}
```

**Output:**
```typescript
{
  content: string;       // File contents
  size: number;          // Size in bytes
  exists: boolean;       // Whether file exists
  modified?: number;     // Last modified timestamp (epoch ms)
}
```

**Example:**
```typescript
const result = await tools.fs.read({ path: "README.md" });
if (result.exists) {
  console.log(result.content);
}
```

---

#### `fs.write`
Write content to a file.

**Input:**
```typescript
{
  path: string;          // Path to file
  content: string;       // Content to write
  encoding?: "utf8" | "base64";  // Default: "utf8"
  append?: boolean;      // Default: false
}
```

**Output:**
```typescript
{
  success: boolean;
  path: string;
  size: number;
  error?: string;
}
```

**Example:**
```typescript
await tools.fs.write({
  path: "output.txt",
  content: "Hello, World!"
});
```

---

#### `fs.glob`
Find files matching a glob pattern.

**Input:**
```typescript
{
  pattern: string;       // Glob pattern (e.g., "**/*.ts")
  root?: string;         // Default: current directory
  dot?: boolean;         // Include dotfiles, default: false
  maxDepth?: number;     // Default: Infinity
}
```

**Output:**
```typescript
{
  files: string[];       // Matching file paths
  count: number;
  root: string;
}
```

**Example:**
```typescript
const result = await tools.fs.glob({ pattern: "**/*.ts" });
console.log(`Found ${result.count} TypeScript files`);
```

---

#### `fs.mkdir`
Create a directory.

**Input:**
```typescript
{
  path: string;
  recursive?: boolean;   // Create parents, default: true
}
```

**Output:**
```typescript
{
  success: boolean;
  path: string;
  existed: boolean;      // Was already present
  error?: string;
}
```

---

#### `fs.delete`
Delete a file or directory.

**Input:**
```typescript
{
  path: string;
  recursive?: boolean;   // For directories, default: false
}
```

**Output:**
```typescript
{
  success: boolean;
  path: string;
  existed: boolean;
  error?: string;
}
```

---

### git (Version Control)

Tools for git operations.

#### `git.status`
Get repository status.

**Input:**
```typescript
{
  path?: string;         // Repository path, default: cwd
}
```

**Output:**
```typescript
{
  isRepo: boolean;
  branch: string;
  isClean: boolean;
  modified: string[];
  untracked: string[];
  staged: string[];
  deleted: string[];
  renamed: { old: string; new: string }[];
  ahead?: number;
  behind?: number;
}
```

---

#### `git.diff`
Get diff between commits or working tree.

**Input:**
```typescript
{
  path?: string;
  from?: string;         // Default: "HEAD"
  to?: string;           // Compare range
  file?: string;         // Filter by file
}
```

**Output:**
```typescript
{
  success: boolean;
  diff: string;
  hasChanges: boolean;
  filesChanged: number;
}
```

---

#### `git.commit`
Create a commit.

**Input:**
```typescript
{
  path?: string;
  message: string;
  all?: boolean;         // Stage all changes
  files?: string[];      // Stage specific files
}
```

**Output:**
```typescript
{
  success: boolean;
  hash?: string;
  error?: string;
}
```

---

#### `git.log`
Get commit history.

**Input:**
```typescript
{
  path?: string;
  limit?: number;        // Default: 10
  file?: string;         // Filter by file
  stat?: boolean;        // Include changed files
}
```

**Output:**
```typescript
{
  success: boolean;
  commits: Array<{
    hash: string;
    shortHash: string;
    author: string;
    email: string;
    date: string;
    message: string;
    files?: string[];
  }>;
  total?: number;
}
```

---

#### `git.branch`
Manage branches.

**Input:**
```typescript
{
  path?: string;
  list?: boolean;        // List branches (default: true)
  create?: string;       // Create new branch
  from?: string;         // Branch from
  switch?: string;       // Switch to branch
  delete?: string;       // Delete branch
  force?: boolean;
}
```

**Output:**
```typescript
{
  success: boolean;
  current?: string;
  branches?: Array<{
    name: string;
    current: boolean;
    remote?: string;
    ahead?: number;
    behind?: number;
  }>;
}
```

---

### http (Network)

Tools for HTTP requests.

#### `http.fetch`
Make a GET request.

**Input:**
```typescript
{
  url: string;
  headers?: Record<string, string>;
  followRedirects?: boolean;  // Default: true
  timeout?: number;          // ms, default: 30000
}
```

**Output:**
```typescript
{
  success: boolean;
  status: number;
  headers: Record<string, string>;
  body: string;
  size: number;
}
```

---

#### `http.post`
Make a POST request.

**Input:**
```typescript
{
  url: string;
  body?: unknown;
  contentType?: string;      // Default: "application/json"
  headers?: Record<string, string>;
  timeout?: number;          // ms, default: 30000
}
```

**Output:**
```typescript
{
  success: boolean;
  status: number;
  headers: Record<string, string>;
  body: string;
  json?: unknown;            // Parsed JSON if applicable
}
```

---

#### `http.download`
Download a file.

**Input:**
```typescript
{
  url: string;
  destination: string;
  headers?: Record<string, string>;
  timeout?: number;          // ms, default: 60000
}
```

**Output:**
```typescript
{
  success: boolean;
  path: string;
  size: number;
  contentType?: string;
}
```

---

### search (Search)

Tools for searching files and content.

#### `search.grep`
Search file contents.

**Input:**
```typescript
{
  pattern: string;
  path?: string;             // Default: cwd
  recursive?: boolean;       // Default: true
  ignoreCase?: boolean;
  regex?: boolean;           // Default: true
  maxResults?: number;       // Default: 100
  include?: string;          // File glob
  exclude?: string;          // File glob
}
```

**Output:**
```typescript
{
  success: boolean;
  matches: Array<{
    file: string;
    line: number;
    content: string;
    column?: number;
  }>;
  count: number;
}
```

---

#### `search.find`
Find files by name/pattern.

**Input:**
```typescript
{
  path?: string;
  name?: string;             // Glob pattern
  pattern?: string;          // Regex pattern
  type?: "f" | "d";          // File or directory
  maxDepth?: number;
  minSize?: number;          // Bytes
  maxSize?: number;          // Bytes
  modifiedAfter?: number;    // Epoch ms
  modifiedBefore?: number;   // Epoch ms
}
```

**Output:**
```typescript
{
  success: boolean;
  files: Array<{
    path: string;
    name: string;
    size: number;
    isDirectory: boolean;
    modified: number;
  }>;
  count: number;
}
```

---

### shell (Execution)

#### `shell.exec`
Execute a shell command.

**Input:**
```typescript
{
  command: string;
  args?: string[];
  cwd?: string;
  env?: Record<string, string>;
  timeout?: number;          // ms, default: 60000
  maxOutput?: number;        // Bytes, default: 10MB
}
```

**Output:**
```typescript
{
  success: boolean;
  code: number;
  stdout: string;
  stderr: string;
  output: string;            // Combined stdout + stderr
  executionTime: number;     // ms
}
```

---

## Progress Reporting

Use the `progress()` function to report execution progress:

```typescript
progress("Starting task");

const files = await tools.fs.glob({ pattern: "**/*.md" });
progress("Found files", { count: files.length });

for (let i = 0; i < files.files.length; i++) {
  await processFile(files.files[i]);
  progress("Processing", { 
    current: i + 1, 
    total: files.files.length 
  });
}

progress("Complete", { processed: files.files.length });
```

Progress logs are returned in the execution result.

---

## Examples

### Batch file processing
```typescript
const files = await tools.fs.glob({ pattern: "src/**/*.ts" });
const results = [];

for (const file of files.files) {
  const content = await tools.fs.read({ path: file });
  if (content.exists) {
    const todoCount = (content.content.match(/TODO/g) || []).length;
    results.push({ file, todoCount });
  }
}

return results.filter(r => r.todoCount > 0);
```

### Git workflow
```typescript
// Check status
const status = await tools.git.status();

if (!status.isClean) {
  // Stage and commit
  await tools.git.commit({
    message: "Auto-commit: Updates",
    all: true
  });
  
  return { committed: true };
}

return { committed: false, reason: "No changes" };
```

### Web scraping
```typescript
const response = await tools.http.fetch({ 
  url: "https://api.example.com/data" 
});

if (response.success) {
  const data = JSON.parse(response.body);
  
  // Save to file
  await tools.fs.write({
    path: "data.json",
    content: JSON.stringify(data, null, 2)
  });
  
  return { saved: true, items: data.length };
}

return { saved: false, error: response.error };
```

---

## Adding Custom Tools

Create a file in `.tools/tools/custom/my-tool.ts`:

```typescript
export interface Input {
  query: string;
}

export interface Output {
  result: string;
}

export default async function myTool(input: Input): Promise<Output> {
  // Implementation
  return { result: `Processed: ${input.query}` };
}
```

Then use it:
```typescript
const result = await tools.custom.myTool({ query: "test" });
```

---

## Error Handling

All tools return a `success` boolean. Check this before using results:

```typescript
const result = await tools.fs.read({ path: "file.txt" });

if (!result.success) {
  console.error("Failed:", result.error);
  return { error: result.error };
}

// Use result.content
```

For git operations, also check `isRepo`:

```typescript
const status = await tools.git.status();
if (!status.isRepo) {
  return { error: "Not a git repository" };
}
```
