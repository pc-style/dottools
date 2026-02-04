#!/bin/bash
#
# Shell Tool: exec - Execute shell commands (Shell Fallback)
# This is essentially the executor itself, so it's simpler
#

tools_shell_exec() {
  local input
  local command
  local args
  local cwd
  local env
  local timeout
  local maxOutput
  
  # Read input from stdin
  input=$(cat)
  command=$(echo "$input" | jq -r '.command // empty')
  args=$(echo "$input" | jq -r '.args // empty')
  cwd=$(echo "$input" | jq -r '.cwd // empty')
  env=$(echo "$input" | jq -r '.env // empty')
  timeout=$(echo "$input" | jq -r '.timeout // 60')
  maxOutput=$(echo "$input" | jq -r '.maxOutput // 10485760')
  
  if [ -z "$command" ]; then
    echo '{"success":false,"code":-1,"stdout":"","stderr":"","output":"","executionTime":0,"error":"Missing required field: command"}'
    return 1
  fi
  
  local start_time
  start_time=$(date +%s%N 2>/dev/null || echo "$(date +%s)000000000")
  
  # Parse args array
  local cmd_args=()
  if [ -n "$args" ] && [ "$args" != "null" ] && [ "$args" != "[]" ]; then
    while IFS= read -r arg; do
      [ -z "$arg" ] && continue
      cmd_args+=("$arg")
    done <<< "$(echo "$args" | jq -r '.[]')"
  fi
  
  # Build command with timeout
  local full_cmd="$command ${cmd_args[*]}"
  
  # Set up environment if provided
  if [ -n "$env" ] && [ "$env" != "null" ]; then
    local env_vars=""
    local env_keys
    env_keys=$(echo "$env" | jq -r 'keys[]')
    while IFS= read -r key; do
      [ -z "$key" ] && continue
      local value
      value=$(echo "$env" | jq -r ".[\"$key\"]")
      env_vars="$env_vars $key='$value'"
    done <<< "$env_keys"
    full_cmd="env $env_vars $full_cmd"
  fi
  
  # Change directory if needed
  if [ -n "$cwd" ] && [ "$cwd" != "null" ]; then
    full_cmd="(cd '$cwd' && $full_cmd)"
  fi
  
  # Execute with timeout
  local output
  local exit_code
  
  if command -v timeout >/dev/null 2>&1; then
    output=$(timeout "$timeout" bash -c "$full_cmd" 2>&1)
    exit_code=$?
  else
    output=$(bash -c "$full_cmd" 2>&1)
    exit_code=$?
  fi
  
  local end_time
  end_time=$(date +%s%N 2>/dev/null || echo "$(date +%s)000000000")
  local execution_time=$(( (end_time - start_time) / 1000000 ))
  
  # Truncate output if too large
  local output_len=${#output}
  if [ "$output_len" -gt "$maxOutput" ]; then
    output="${output:0:maxOutput}
[truncated]"
  fi
  
  # Determine success
  local success="false"
  if [ "$exit_code" -eq 0 ]; then
    success="true"
  fi
  
  # Escape output for JSON
  local output_escaped
  output_escaped=$(echo "$output" | jq -Rs '.')
  
  # For shell version, we combine stdout/stderr
  jq -n \
    --argjson success "$success" \
    --argjson code "$exit_code" \
    --argjson output "$output_escaped" \
    --argjson executionTime "$execution_time" \
    '{
      success: $success,
      code: $code,
      stdout: $output,
      stderr: "",
      output: $output,
      executionTime: $executionTime
    }'
}

# Allow direct execution
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  tools_shell_exec "$@"
fi
