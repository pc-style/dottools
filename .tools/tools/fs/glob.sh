#!/bin/bash
#
# FS Tool: glob - Find files matching a pattern (Shell Fallback)
#

tools_fs_glob() {
  local input
  local pattern
  local root
  local dot
  local maxDepth
  local files
  
  # Read input from stdin
  input=$(cat)
  pattern=$(echo "$input" | jq -r '.pattern // empty')
  root=$(echo "$input" | jq -r '.root // "."')
  dot=$(echo "$input" | jq -r '.dot // false')
  maxDepth=$(echo "$input" | jq -r '.maxDepth // 999')
  
  if [ -z "$pattern" ]; then
    echo '{"files":[],"count":0,"root":"."}'
    return 0
  fi
  
  cd "$root" || {
    echo '{"error":"Failed to change to root directory"}'
    return 1
  }
  
  # Use find with pattern matching
  local find_opts=""
  if [ "$dot" = "false" ]; then
    find_opts="-not -path '*/\.*'"
  fi
  
  # Convert glob pattern to find pattern (basic conversion)
  # This is a simplified version - full glob support requires more complex handling
  local find_pattern
  find_pattern=$(echo "$pattern" | sed 's/\*\*/.*/g; s/\*/[^\/]*/g')
  
  # Use find with maxdepth
  files=$(find . -maxdepth "$maxDepth" -type f $find_opts 2>/dev/null | \
    grep -E "^\./${find_pattern}$" | \
    sed 's|^\./||' | \
    sort)
  
  # Convert to JSON array
  local json_files
  json_files=$(echo "$files" | jq -R -s -c 'split("\n") | map(select(length > 0))')
  
  local count
  count=$(echo "$json_files" | jq 'length')
  
  jq -n \
    --argjson files "$json_files" \
    --argjson count "$count" \
    --arg root "$root" \
    '{
      files: $files,
      count: $count,
      root: $root
    }'
}

# Allow direct execution
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  tools_fs_glob "$@"
fi
