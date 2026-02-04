# PTC Harness

**Programmatic Tool Calling Harness** - Universal tool execution for AI agents

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/yourusername/ptc-harness)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

PTC Harness enables AI coding agents to write and execute code that orchestrates multiple tools in a single pass, dramatically reducing token usage and latency compared to traditional sequential tool calling.

## Features

- **Dual Runtime**: TypeScript via Deno (primary) + Bash fallback (universal compatibility)
- **Universal**: Works with any AI agent that can execute shell commands
- **Built-in Tools**: Filesystem, Git, HTTP, Search, and Shell execution
- **Extensible**: Easy to add custom tools
- **AGENTS.md Native**: First-class support for the agents.md standard
- **JSON In/Out**: Structured data everywhere for reliable parsing
- **Zero Dependencies**: Works with just bash, enhanced with Deno

## Quick Start

### Installation

**Option 1: curl | bash (Recommended)**
```bash
curl -fsSL https://ptc-harness.dev/install.sh | bash
```

**Option 2: npx**
```bash
npx ptc-harness init
```

**Option 3: Manual**
```bash
git clone https://github.com/yourusername/ptc-harness.git .tools
```

### Basic Usage

```bash
# Execute code with the harness
.tools/executor <<'CODE'
const files = await tools.fs.glob({ pattern: "**/*.ts" });
const results = [];

for (const file of files.files) {
  const content = await tools.fs.read({ path: file });
  results.push({ file, size: content.size });
}

return results;
CODE
```

### With Shell Fallback (No Deno Required)

```bash
.tools/executor.sh <<'CODE'
# Shell version uses function-based tools
echo "$(tools_fs_read '{"path":"README.md"}' | jq -r '.content')"
CODE
```

## Available Tools

### Filesystem (`tools.fs.*`)
- `read` - Read file contents
- `write` - Write to files
- `glob` - Find files matching patterns
- `mkdir` - Create directories
- `delete` - Delete files/directories

### Git (`tools.git.*`)
- `status` - Repository status
- `diff` - Compare commits
- `commit` - Create commits
- `log` - View history
- `branch` - Manage branches

### HTTP (`tools.http.*`)
- `fetch` - GET requests
- `post` - POST requests
- `download` - Download files

### Search (`tools.search.*`)
- `grep` - Search file contents
- `find` - Find files by criteria

### Shell (`tools.shell.*`)
- `exec` - Execute commands

## Examples

### Batch Processing

```typescript
const files = await tools.fs.glob({ pattern: "src/**/*.ts" });
const todos = [];

for (const file of files.files) {
  const content = await tools.fs.read({ path: file });
  if (content.exists) {
    const matches = (content.content.match(/TODO.*/g) || []);
    if (matches.length > 0) {
      todos.push({ file, count: matches.length });
    }
  }
}

return {
  totalFiles: files.count,
  filesWithTodos: todos.length,
  todos
};
```

### Git Workflow

```typescript
// Check repository status
const status = await tools.git.status();

if (!status.isClean) {
  // Stage all changes and commit
  await tools.git.commit({
    message: "chore: automated updates",
    all: true
  });
  
  return { committed: true, branch: status.branch };
}

return { committed: false, reason: "No changes" };
```

### Web Scraping

```typescript
// Fetch data from API
const response = await tools.http.fetch({ 
  url: "https://api.github.com/repos/denoland/deno" 
});

if (response.success) {
  const data = JSON.parse(response.body);
  
  // Save to file
  await tools.fs.write({
    path: "deno-info.json",
    content: JSON.stringify(data, null, 2)
  });
  
  return { 
    saved: true, 
    stars: data.stargazers_count,
    forks: data.forks_count
  };
}

return { saved: false, error: response.error };
```

## Why Programmatic Tool Calling?

Traditional AI agents call tools one at a time:
```
User → Agent → Tool1 → Agent → Tool2 → Agent → Result
```

With PTC, the agent writes code that calls all tools programmatically:
```
User → Agent → [Code executes Tool1, Tool2, ...] → Agent → Result
```

**Benefits:**
- **Reduced Tokens**: No intermediate results in context
- **Lower Latency**: Single round-trip instead of many
- **Conditional Logic**: Branch based on intermediate results
- **Batch Operations**: Process 1000 items in one go
- **Error Handling**: Try/catch with retries

## Adding Custom Tools

Create `.tools/tools/custom/my-tool.ts`:

```typescript
export interface Input {
  query: string;
}

export interface Output {
  result: string;
}

export default async function myTool(input: Input): Promise<Output> {
  // Your implementation
  return { result: `Processed: ${input.query}` };
}
```

Use it immediately:
```typescript
const result = await tools.custom.myTool({ query: "test" });
```

## CLI Usage

```bash
# Initialize in current directory
ptc init

# Execute code
ptc exec <<'CODE'
const result = await tools.fs.read({ path: "README.md" });
return result;
CODE

# List all tools
ptc list

# Create custom tool template
ptc add-tool my-custom-tool

# View documentation
ptc docs
```

## Configuration

Edit `.tools/ptc.json`:

```json
{
  "version": "1.0.0",
  "executor": {
    "primary": "deno",
    "fallback": "bash",
    "timeout": 30000
  },
  "sandbox": {
    "enabled": false
  },
  "tools": {
    "builtin": ["fs", "git", "http", "search", "shell"],
    "custom": []
  }
}
```

## AGENTS.md Integration

The installer automatically updates `AGENTS.md` with PTC instructions, so AI agents know how to use it:

```markdown
## Programmatic Tool Calling

This project has `.tools/` installed which enables programmatic tool calling.

### Usage
.tools/executor <<'CODE'
const files = await tools.fs.glob({ pattern: "**/*.ts" });
// ... your code
CODE
```

## Dependencies

**Required:**
- Bash (any modern version)

**Recommended:**
- Deno 2.0+ (for TypeScript support and better performance)
- jq (for better JSON handling)
- curl (for HTTP tools)

## Architecture

```
Agent → .tools/executor → TypeScript Executor (Deno)
                              ↓
                    Tool Proxy → Tool Loader
                              ↓
                    Tool Implementation (.ts or .sh)
                              ↓
                         Result (JSON)
```

If Deno is not available, the Bash fallback is used:

```
Agent → .tools/executor.sh → Tool Functions (Shell)
                              ↓
                         Result (JSON)
```

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](LICENSE) file

## Acknowledgements

Inspired by:
- [Anthropic's Programmatic Tool Calling](https://platform.claude.com/docs/en/agents-and-tools/tool-use/programmatic-tool-calling)
- [Letta's implementation](https://www.letta.com/blog/programmatic-tool-calling-with-any-llm)
- [Codecall](https://github.com/zeke-john/codecall)
- [AGENTS.md](https://agents.md/)
