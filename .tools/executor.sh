#!/bin/bash
#
# Programmatic Tool Calling (PTC) Executor - Bash Fallback Version
#
# This is a lightweight fallback when Deno is not available.
# Supports the same tools but with shell-based implementations.
#
# Usage:
#   .tools/executor.sh <<'CODE'
#   files=$(tools_fs_glob "**/*.sh")
#   for f in $files; do
#     content=$(tools_fs_read "$f")
#     echo "$f: ${#content}"
#   done
#   CODE

set -e

PTC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all tool functions
source "$PTC_DIR/lib/utils.sh"

# Load all tool modules
for tool_dir in "$PTC_DIR/tools/"*/; do
  if [ -d "$tool_dir" ]; then
    for tool_file in "$tool_dir"*.sh; do
      if [ -f "$tool_file" ]; then
        source "$tool_file"
      fi
    done
  fi
done

# Progress logging
progress_logs="[]"

progress() {
  local step="$1"
  local data="${2:-null}"
  local timestamp
  timestamp=$(date +%s000)
  
  local log
  log=$(jq -n \
    --arg step "$step" \
    --argjson data "$data" \
    --argjson timestamp "$timestamp" \
    '{step: $step, data: $data, timestamp: $timestamp}')
  
  progress_logs=$(echo "$progress_logs" | jq ". + [$log]")
  
  # Output for real-time streaming to stderr
  echo "{\"type\":\"progress\",\"step\":\"$step\",\"timestamp\":$timestamp}" >&2
}

# Main execution
main() {
  local code
  local start_time
  local end_time
  local execution_time
  local output
  local status="success"
  local error_message=""
  local error_type=""
  
  start_time=$(date +%s%N)
  
  # Read code from stdin
  code=$(cat)
  
  if [ -z "$code" ]; then
    echo '{
      "status": "error",
      "output": null,
      "error": {
        "message": "No code provided. Usage: .tools/executor.sh <<< '\''CODE'\'' ... CODE",
        "type": "NoInputError"
      },
      "progressLogs": [],
      "executionTime": 0
    }'
    exit 1
  fi
  
  # Execute code in a subshell to capture output and handle errors
  output=$(
    set +e
    (
      set -e
      eval "$code"
    ) 2>&1
  ) || {
    status="error"
    error_message="$output"
    error_type="ExecutionError"
    output=""
  }
  
  end_time=$(date +%s%N)
  execution_time=$(( (end_time - start_time) / 1000000 ))
  
  # Build result JSON
  if [ "$status" = "success" ]; then
    jq -n \
      --arg output "$output" \
      --argjson progressLogs "$progress_logs" \
      --argjson executionTime "$execution_time" \
      '{
        status: "success",
        output: $output,
        progressLogs: $progressLogs,
        executionTime: $executionTime
      }'
  else
    jq -n \
      --arg message "$error_message" \
      --arg type "$error_type" \
      --argjson progressLogs "$progress_logs" \
      --argjson executionTime "$execution_time" \
      '{
        status: "error",
        output: null,
        error: {
          message: $message,
          type: $type
        },
        progressLogs: $progressLogs,
        executionTime: $executionTime
      }'
  fi
}

main "$@"
