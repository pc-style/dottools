#!/bin/bash
#
# HTTP Tool: post - Make HTTP POST request (Shell Fallback)
# Requires curl
#

tools_http_post() {
  local input
  local url
  local body
  local contentType
  local headers
  local timeout
  
  # Read input from stdin
  input=$(cat)
  url=$(echo "$input" | jq -r '.url // empty')
  body=$(echo "$input" | jq -r '.body // empty')
  contentType=$(echo "$input" | jq -r '.contentType // "application/json"')
  headers=$(echo "$input" | jq -r '.headers // empty')
  timeout=$(echo "$input" | jq -r '.timeout // 30')
  
  if [ -z "$url" ]; then
    echo '{"success":false,"status":0,"headers":{},"body":"","error":"Missing required field: url"}'
    return 1
  fi
  
  # Check for curl
  if ! command -v curl >/dev/null 2>&1; then
    echo '{"success":false,"status":0,"headers":{},"body":"","error":"curl is required but not installed"}'
    return 1
  fi
  
  # Build curl command
  local args=(-s -w "\n%{http_code}\n%{content_type}")
  args+=(-X POST)
  args+=(--max-time "$timeout")
  
  # Add content type
  args+=(-H "Content-Type: $contentType")
  
  # Add custom headers
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
  
  # Add body
  if [ -n "$body" ] && [ "$body" != "null" ]; then
    if [ "$contentType" = "application/json" ] && [ "$body" != "null" ]; then
      # Body might already be a JSON string
      if echo "$body" | jq -e '.' >/dev/null 2>&1; then
        args+=(-d "$body")
      else
        args+=(-d "$body")
      fi
    else
      args+=(-d "$body")
    fi
  fi
  
  args+=("$url")
  
  # Execute curl
  local response
  response=$(curl "${args[@]}" 2>/dev/null)
  
  if [ $? -ne 0 ]; then
    echo '{"success":false,"status":0,"headers":{},"body":"","error":"Request failed"}'
    return 1
  fi
  
  # Parse response
  local response_body
  local status
  local content_type
  
  response_body=$(echo "$response" | sed '$d;$d')
  status=$(echo "$response" | tail -2 | head -1)
  content_type=$(echo "$response" | tail -1)
  
  # Determine success
  local success="false"
  if [ "$status" -ge 200 ] && [ "$status" -lt 300 ]; then
    success="true"
  fi
  
  # Try to parse as JSON
  local json="null"
  if echo "$response_body" | jq -e '.' >/dev/null 2>&1; then
    json=$(echo "$response_body" | jq '.')
  fi
  
  # Escape body for JSON
  local body_escaped
  body_escaped=$(echo "$response_body" | jq -Rs '.')
  
  jq -n \
    --argjson success "$success" \
    --argjson status "$status" \
    --argjson body "$body_escaped" \
    --argjson json "$json" \
    '{
      success: $success,
      status: $status,
      headers: {},
      body: $body,
      json: $json
    }'
}

# Allow direct execution
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  tools_http_post "$@"
fi
