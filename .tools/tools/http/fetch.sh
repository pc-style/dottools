#!/bin/bash
#
# HTTP Tool: fetch - Make HTTP GET request (Shell Fallback)
# Requires curl
#

tools_http_fetch() {
  local input
  local url
  local headers
  local followRedirects
  local timeout
  
  # Read input from stdin
  input=$(cat)
  url=$(echo "$input" | jq -r '.url // empty')
  headers=$(echo "$input" | jq -r '.headers // empty')
  followRedirects=$(echo "$input" | jq -r '.followRedirects // true')
  timeout=$(echo "$input" | jq -r '.timeout // 30')
  
  if [ -z "$url" ]; then
    echo '{"success":false,"status":0,"headers":{},"body":"","size":0,"error":"Missing required field: url"}'
    return 1
  fi
  
  # Check for curl
  if ! command -v curl >/dev/null 2>&1; then
    echo '{"success":false,"status":0,"headers":{},"body":"","size":0,"error":"curl is required but not installed"}'
    return 1
  fi
  
  # Build curl command
  local args=(-s -w "\n%{http_code}\n%{content_type}\n%{size_download}")
  
  if [ "$followRedirects" = "true" ]; then
    args+=(-L)
  fi
  
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
  local response
  response=$(curl "${args[@]}" 2>/dev/null)
  
  if [ $? -ne 0 ]; then
    echo '{"success":false,"status":0,"headers":{},"body":"","size":0,"error":"Request failed"}'
    return 1
  fi
  
  # Parse response
  local body
  local status
  local content_type
  local size
  
  body=$(echo "$response" | sed '$d;$d;$d')
  status=$(echo "$response" | tail -3 | head -1)
  content_type=$(echo "$response" | tail -2 | head -1)
  size=$(echo "$response" | tail -1)
  
  # Determine success based on status code
  local success="false"
  if [ "$status" -ge 200 ] && [ "$status" -lt 300 ]; then
    success="true"
  fi
  
  # Escape body for JSON
  local body_escaped
  body_escaped=$(echo "$body" | jq -Rs '.')
  
  jq -n \
    --argjson success "$success" \
    --argjson status "$status" \
    --argjson body "$body_escaped" \
    --argjson size "$size" \
    '{
      success: $success,
      status: $status,
      headers: {},
      body: $body,
      size: $size
    }'
}

# Allow direct execution
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  tools_http_fetch "$@"
fi
