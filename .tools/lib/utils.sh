#!/bin/bash
#
# Utility functions for PTC Bash executor
#

# Safe JSON parsing
parse_json() {
  local json="$1"
  local key="$2"
  echo "$json" | jq -r "$key // empty"
}

# Check if value is valid JSON
is_json() {
  local value="$1"
  echo "$value" | jq -e '.' > /dev/null 2>&1
}

# Escape string for JSON
json_escape() {
  local str="$1"
  printf '%s' "$str" | jq -Rs '.'
}

# Convert exit code to error type
exit_code_to_error() {
  local code="$1"
  case "$code" in
    1) echo "GeneralError" ;;
    2) echo "MisuseOfShell" ;;
    126) echo "CommandNotExecutable" ;;
    127) echo "CommandNotFound" ;;
    128) echo "InvalidExitArg" ;;
    130) echo "Interrupted" ;;
    *) echo "ExitCode$code" ;;
  esac
}

# Check if a command exists
command_exists() {
  command -v "$1" > /dev/null 2>&1
}

# Get file mime type (if file command available)
get_mime_type() {
  local filepath="$1"
  if command_exists file; then
    file --brief --mime-type "$filepath" 2>/dev/null || echo "application/octet-stream"
  else
    echo "application/octet-stream"
  fi
}

# Safe file size
get_file_size() {
  local filepath="$1"
  if [ -f "$filepath" ]; then
    stat -f%z "$filepath" 2>/dev/null || stat -c%s "$filepath" 2>/dev/null || echo "0"
  else
    echo "0"
  fi
}

# Format bytes to human readable
format_bytes() {
  local bytes="$1"
  if [ "$bytes" -lt 1024 ]; then
    echo "${bytes}B"
  elif [ "$bytes" -lt 1048576 ]; then
    echo "$(($bytes / 1024))KB"
  elif [ "$bytes" -lt 1073741824 ]; then
    echo "$(($bytes / 1048576))MB"
  else
    echo "$(($bytes / 1073741824))GB"
  fi
}

# Check if path is absolute
is_absolute_path() {
  local path="$1"
  [[ "$path" = /* ]]
}

# Resolve relative path to absolute
resolve_path() {
  local path="$1"
  local base="${2:-$PWD}"
  
  if is_absolute_path "$path"; then
    echo "$path"
  else
    echo "$base/$path"
  fi
}

# Create temp file and return path
temp_file() {
  mktemp -t ptc.XXXXXX
}

# Create temp directory and return path
temp_dir() {
  mktemp -d -t ptc.XXXXXX
}

# Clean up temp files (register with trap)
cleanup() {
  local pattern="${1:-$TMPDIR/ptc.*}"
  rm -rf $pattern 2>/dev/null || true
}

# URL encode string
url_encode() {
  local str="$1"
  printf '%s' "$str" | jq -sRr '@uri'
}

# URL decode string
url_decode() {
  local str="$1"
  printf '%s' "$str" | jq -sRr '@uri'
}

# Check if running in CI environment
is_ci() {
  [ -n "$CI" ] || [ -n "$CONTINUOUS_INTEGRATION" ] || [ -n "$GITHUB_ACTIONS" ]
}

# Get platform
get_platform() {
  uname -s | tr '[:upper:]' '[:lower:]'
}

# Check if on macOS
is_macos() {
  [[ "$(get_platform)" == "darwin" ]]
}

# Check if on Linux
is_linux() {
  [[ "$(get_platform)" == "linux" ]]
}
