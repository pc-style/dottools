#!/bin/bash
#
# Search Tool: rg - Use ripgrep for fast searching (Shell Fallback)
#

tools_search_rg() {
  local input
  local pattern
  local path
  local glob
  local ignoreCase
  local fixedStrings
  local maxResults
  local lineNumbers
  local type
  
  # Read input from stdin
  input=$(cat)
  pattern=$(echo "$input" | jq -r '.pattern // empty')
  path=$(echo "$input" | jq -r '.path // "."')
  glob=$(echo "$input" | jq -r '.glob // empty')
  ignoreCase=$(echo "$input" | jq -r '.ignoreCase // false')
  fixedStrings=$(echo "$input" | jq -r '.fixedStrings // false')
  maxResults=$(echo "$input" | jq -r '.maxResults // 100')
  lineNumbers=$(echo "$input" | jq -r '.lineNumbers // true')
  type=$(echo "$input" | jq -r '.type // empty')
  
  if [ -z "$pattern" ]; then
    echo '{"success":false,"matches":[],"count":0,"error":"Missing required field: pattern"}'
    return 1
  fi
  
  # Check if ripgrep is available
  if ! command -v rg > /dev/null 2>&1; then
    echo '{"success":false,"matches":[],"count":0,"error":"ripgrep (rg) is not installed"}'
    return 1
  fi
  
  # Build rg arguments
  local args=(--json --line-number --column)
  
  [ "$ignoreCase" = "true" ] && args+=(--ignore-case)
  [ "$fixedStrings" = "true" ] && args+=(--fixed-strings)
  [ -n "$glob" ] && args+=(--glob "$glob")
  [ -n "$type" ] && args+=(--type "$type")
  
  args+=(--max-count "$maxResults")
  args+=("$pattern")
  args+=("$path")
  
  # Execute ripgrep
  local output
  output=$(rg "${args[@]}" 2>/dev/null)
  local exit_code=$?
  
  # Exit code 1 means no matches, which is fine
  if [ "$exit_code" -ne 0 ] && [ "$exit_code" -ne 1 ]; then
    echo '{"success":false,"matches":[],"count":0,"error":"ripgrep execution failed"}'
    return 1
  fi
  
  # Parse JSON output
  local matches="[]"
  
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    
    local type_field
    type_field=$(echo "$line" | jq -r '.type // empty')
    
    if [ "$type_field" = "match" ]; then
      local file
      local line_num
      local column
      local content
      
      file=$(echo "$line" | jq -r '.data.path.text // .data.path // empty')
      [ -z "$file" ] && file="$path"
      
      line_num=$(echo "$line" | jq -r '.data.line_number // 0')
      column=$(echo "$line" | jq -r '.data.submatches[0].start // 0')
      column=$((column + 1))
      content=$(echo "$line" | jq -r '.data.lines.text // ""' | tr -d '\n')
      
      local match
      match=$(jq -n \
        --arg file "$file" \
        --argjson line "$line_num" \
        --argjson column "$column" \
        --arg content "$content" \
        '{
          file: $file,
          line: $line,
          column: $column,
          content: $content
        }')
      
      matches=$(echo "$matches" | jq ". + [$match]")
    fi
  done <<< "$output"
  
  local count
  count=$(echo "$matches" | jq 'length')
  
  jq -n \
    --argjson success "true" \
    --argjson matches "$matches" \
    --argjson count "$count" \
    '{
      success: $success,
      matches: $matches,
      count: $count
    }'
}

# Allow direct execution
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  tools_search_rg "$@"
fi
