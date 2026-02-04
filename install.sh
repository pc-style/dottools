#!/bin/bash
#
# PTC Harness Installation Script
# 
# Install with: curl -fsSL https://ptc-harness.dev/install.sh | bash
# Or: curl -fsSL https://raw.githubusercontent.com/user/repo/main/install.sh | bash
#

set -e

PTC_VERSION="1.0.0"
REPO_URL="${PTC_REPO:-https://github.com/yourusername/ptc-harness}"
INSTALL_DIR="${PTC_INSTALL_DIR:-.}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Check dependencies
check_deps() {
  log_info "Checking dependencies..."
  
  # Check for git
  if ! command -v git > /dev/null 2>&1; then
    log_error "Git is required but not installed"
    exit 1
  fi
  
  # Check for Deno (optional but recommended)
  if command -v deno > /dev/null 2>&1; then
    DENO_VERSION=$(deno --version | head -1 | cut -d' ' -f2)
    log_success "Deno found: $DENO_VERSION"
  else
    log_warning "Deno not found. Shell fallback will be used."
    log_info "Install Deno for better performance: https://deno.land/manual/getting_started/installation"
  fi
  
  # Check for jq
  if ! command -v jq > /dev/null 2>&1; then
    log_warning "jq not found. Some features may be limited."
  fi
}

# Install PTC harness
install_ptc() {
  local target_dir="$1"
  
  log_info "Installing PTC Harness v$PTC_VERSION to $target_dir/.tools"
  
  # Create target directory
  mkdir -p "$target_dir"
  cd "$target_dir"
  
  # Clone or copy the .tools directory
  if [ -d ".tools" ]; then
    log_warning ".tools directory already exists"
    read -p "Overwrite? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      log_info "Installation cancelled"
      exit 0
    fi
    rm -rf .tools
  fi
  
  # Download from GitHub or copy locally
  if [ -n "$PTC_LOCAL_PATH" ]; then
    # Local installation
    log_info "Installing from local path: $PTC_LOCAL_PATH"
    cp -r "$PTC_LOCAL_PATH/.tools" .
  else
    # Clone from GitHub
    log_info "Downloading from GitHub..."
    
    # Create temporary directory
    TMP_DIR=$(mktemp -d)
    trap "rm -rf $TMP_DIR" EXIT
    
    # Clone repository
    git clone --depth 1 "$REPO_URL" "$TMP_DIR/ptc" 2>/dev/null || {
      log_error "Failed to clone repository"
      exit 1
    }
    
    # Copy .tools directory
    cp -r "$TMP_DIR/ptc/.tools" .
  fi
  
  # Make executables executable
  chmod +x .tools/executor.ts 2>/dev/null || true
  chmod +x .tools/executor.sh
  
  log_success "PTC Harness installed successfully!"
}

# Update AGENTS.md
update_agents_md() {
  local target_dir="$1"
  local agents_file="$target_dir/AGENTS.md"
  
  log_info "Updating AGENTS.md..."
  
  if [ -f "$agents_file" ]; then
    # Check if PTC section already exists
    if grep -q "## Programmatic Tool Calling" "$agents_file"; then
      log_warning "AGENTS.md already contains PTC section"
      return
    fi
    
    # Append to existing AGENTS.md
    cat << 'EOF' >> "$agents_file"

## Programmatic Tool Calling

This project has `.tools/` installed which enables programmatic tool calling for AI agents.

### Quick Start

Instead of calling tools one at a time, write code that orchestrates multiple tools:

```bash
# Execute TypeScript (requires Deno)
.tools/executor.ts <<'CODE'
const files = await tools.fs.glob({ pattern: "**/*.ts" });
const results = [];
for (const file of files.files) {
  const content = await tools.fs.read({ path: file });
  results.push({ file, size: content.size });
}
return results;
CODE

# Or use shell fallback (no dependencies)
.tools/executor.sh <<'CODE'
files=$(tools_fs_glob '{"pattern":"**/*.ts"}')
echo "$files"
CODE
```

### Available Tools

- `tools.fs.*` - Filesystem: read, write, glob, mkdir, delete
- `tools.git.*` - Git: status, diff, commit, log, branch  
- `tools.http.*` - HTTP: fetch, post, download
- `tools.search.*` - Search: grep, find
- `tools.shell.*` - Shell: exec

### Full Documentation

See `.tools/sdk/TOOLS.md` for complete documentation.

### Adding Custom Tools

Create `.tools/tools/custom/my-tool.ts` with your tool implementation.
See existing tools for examples.
EOF
    log_success "Updated AGENTS.md"
  else
    # Create new AGENTS.md
    cat << 'EOF' > "$agents_file"
# AGENTS.md

## Programmatic Tool Calling

This project has `.tools/` installed which enables programmatic tool calling for AI agents.

### Quick Start

Instead of calling tools one at a time, write code that orchestrates multiple tools:

```bash
# Execute TypeScript (requires Deno)
.tools/executor.ts <<'CODE'
const files = await tools.fs.glob({ pattern: "**/*.ts" });
const results = [];
for (const file of files.files) {
  const content = await tools.fs.read({ path: file });
  results.push({ file, size: content.size });
}
return results;
CODE

# Or use shell fallback (no dependencies)
.tools/executor.sh <<'CODE'
files=$(tools_fs_glob '{"pattern":"**/*.ts"}')
echo "$files"
CODE
```

### Available Tools

- `tools.fs.*` - Filesystem: read, write, glob, mkdir, delete
- `tools.git.*` - Git: status, diff, commit, log, branch  
- `tools.http.*` - HTTP: fetch, post, download
- `tools.search.*` - Search: grep, find
- `tools.shell.*` - Shell: exec

### Full Documentation

See `.tools/sdk/TOOLS.md` for complete documentation.

### Adding Custom Tools

Create `.tools/tools/custom/my-tool.ts` with your tool implementation.
See existing tools for examples.
EOF
    log_success "Created AGENTS.md"
  fi
}

# Print usage info
print_usage() {
  cat << 'EOF'

PTC Harness Installation
========================

Usage: install.sh [OPTIONS]

Options:
  -d, --dir DIR       Install to specific directory (default: current)
  -l, --local PATH    Install from local path instead of GitHub
  -h, --help          Show this help message

Environment Variables:
  PTC_REPO            GitHub repository URL (default: auto-detected)
  PTC_INSTALL_DIR     Installation directory (default: current)
  PTC_LOCAL_PATH      Local path to copy from (for development)

Examples:
  # Install to current directory
  curl -fsSL https://ptc-harness.dev/install.sh | bash

  # Install to specific directory
  curl -fsSL https://ptc-harness.dev/install.sh | bash -s -- -d /path/to/project

  # Install from local development copy
  PTC_LOCAL_PATH=./ptc-harness ./install.sh

EOF
}

# Main function
main() {
  local target_dir="."
  
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      -d|--dir)
        target_dir="$2"
        shift 2
        ;;
      -l|--local)
        PTC_LOCAL_PATH="$2"
        shift 2
        ;;
      -h|--help)
        print_usage
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        print_usage
        exit 1
        ;;
    esac
  done
  
  # Convert to absolute path
  target_dir=$(cd "$target_dir" && pwd)
  
  echo ""
  echo "╔════════════════════════════════════════╗"
  echo "║     PTC Harness Installation           ║"
  echo "║     Version $PTC_VERSION                   ║"
  echo "╚════════════════════════════════════════╝"
  echo ""
  
  check_deps
  install_ptc "$target_dir"
  update_agents_md "$target_dir"
  
  echo ""
  log_success "Installation complete!"
  echo ""
  echo "Next steps:"
  echo "  1. Review AGENTS.md for usage information"
  echo "  2. Try: .tools/executor.sh <<'CODE' echo 'hello' CODE"
  echo "  3. Install Deno for better performance"
  echo ""
}

# Run main function
main "$@"
