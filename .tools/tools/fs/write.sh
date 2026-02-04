#!/bin/bash
#
# FS Tool: write - Write content to a file (Shell Fallback)
#

tools_fs_write() {
  local input
  local path
  local content
  local encoding
  local append
  local success="false"
  local error=""
  
  # Read input from stdin
  input=$(cat)
  path=$(echo "$input" | jq -r '.path // empty')
  content=$(echo "$input" | jq -r '.content // empty')
  encoding=$(echo "$input" | jq -r '.encoding // "utf8"')
  append=$(echo "$input" | jq -r '.append // false')
  
  if [ -z "$path" ]; then
    echo '{"success":false,"path":"","size":0,"error":"Missing required field: path"}'
    return 1
  fi
  
  # Create parent directory
  parent=$(dirname "$path")
  mkdir -p "$parent" 2>/dev/null || {
    echo "{\"success\":false,\"path\":\"$path\",\"size\":0,\"error\":\"Failed to create directory: $parent\"}"
    return 1
  }
  
  # Decode content if base64
  if [ "$encoding" = "base64" ]; then
    if command -v base64 >/dev/null 2>&1; then
      content=$(echo "$content" | base64 -d 2>/dev/null || echo "$content")
    fi
  fi
  
  # Write file
  if [ "$append" = "true" ]; then
    echo -n "$content" >> "$path" 2>/dev/null && success="true" || error="Failed to append to file"
  else
    echo -n "$content" > "$path" 2>/dev/null && success="true" || error="Failed to write file"
  fi
  
  local size=${#content}
  
  if [ "$success" = "true" ]; then
    jq -n \
      --arg path "$path" \
      --argjson size "$size" \
      --argjson success "$success" \
      '{
        success: $success,
        path: $path,
        size: $size
      }'
  else
    jq -n \
      --arg path "$path" \
      --argjson size "$size" \
      --argjson success "$success" \
      --arg error "$error" \
      '{
        success: $success,
        path: $path,
        size: $size,
        error: $error
      }'
  fi
}

# Allow direct execution
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  tools_fs_write "$@"
fi
