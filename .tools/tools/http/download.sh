#!/bin/bash
#
# HTTP Tool: download - Download file from URL (Shell Fallback)
# Requires curl
#

tools_http_download() {
  local input
  local url
  local destination
  local headers
  local timeout
  
  # Read input from stdin
  input=$(cat)
  url=$(echo "$input" | jq -r '.url // empty')
  destination=$(echo "$input" | jq -r '.destination // empty')
  headers=$(echo "$input" | jq -r '.headers // empty')
  timeout=$(echo "$input" | jq -r '.timeout // 60')
  
  if [ -z "$url" ] || [ -z "$destination" ]; then
    echo '{"success":false,"path":"","size":0,"error":"Missing required fields: url and destination"}'
    return 1
  fi
  
  # Check for curl
  if ! command -v curl >/dev/null 2>&1; then
    echo '{"success":false,"path":"","size":0,"error":"curl is required but not installed"}'
    return 1
  fi
  
  # Create parent directory
  local parent
  parent=$(dirname "$destination")
  mkdir -p "$parent" 2>/dev/null || {
    echo '{"success":false,"path":"","size":0,"error":"Failed to create destination directory"}'
    return 1
  }
  
  # Build curl command
  local args=(-L -s -o "$destination")
  args+=(--max-time "$timeout")
  
  # Add headers
  if [ -n "$headers" ] && [ "$headers" != "null" ]; then
    local header_keys
    header_keys=$(echo "$headers" | jq -r 'keys[]')
    while IFS= read -r key; do
      [ -z "$key" ] && continue
      local value
      value=$(echo "$headers" | jq -r ".[\"$key\"]")
      args+=(-H "$key: $value")
    done <<< "$header_keys"
  fi
  
  args+=("$url")
  
  # Execute curl
  curl "${args[@]}" 2>/dev/null
  
  if [ $? -ne 0 ]; then
    echo '{"success":false,"path":"","size":0,"error":"Download failed"}'
    return 1
  fi
  
  # Get file size
  local size
  if stat -f%z "$destination" >/dev/null 2>&1; then
    # macOS
    size=$(stat -f%z "$destination")
  else
    # Linux
    size=$(stat -c%s "$destination" 2>/dev/null || echo "0")
  fi
  
  # Get content type from file
  local contentType=""
  if command -v file >/dev/null 2>&1; then
    contentType=$(file --brief --mime-type "$destination" 2>/dev/null)
  fi
  
  jq -n \
    --argjson success "true" \
    --arg path "$destination" \
    --argjson size "$size" \
    --arg contentType "$contentType" \
    '{
      success: $success,
      path: $path,
      size: $size,
      contentType: (if $contentType == "" then null else $contentType end)
    }'
}

# Allow direct execution
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  tools_http_download "$@"
fi
