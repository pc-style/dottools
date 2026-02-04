#!/bin/bash
#
# Search Tool: grep - Search file contents (Shell Fallback)
#

tools_search_grep() {
  local input
  local pattern
  local path
  local recursive
  local ignoreCase
  local regex
  local maxResults
  local include
  local exclude
  
  # Read input from stdin
  input=$(cat)
  pattern=$(echo "$input" | jq -r '.pattern // empty')
  path=$(echo "$input" | jq -r '.path // "."')
  recursive=$(echo "$input" | jq -r '.recursive // true')
  ignoreCase=$(echo "$input" | jq -r '.ignoreCase // false')
  regex=$(echo "$input" | jq -r '.regex // true')
  maxResults=$(echo "$input" | jq -r '.maxResults // 100')
  include=$(echo "$input" | jq -r '.include // empty')
  exclude=$(echo "$input" | jq -r '.exclude // empty')
  
  if [ -z "$pattern" ]; then
    echo '{"success":false,"matches":[],"count":0,"error":"Missing required field: pattern"}'
    return 1
  fi
  
  # Try ripgrep first
  local use_rg="false"
  if command -v rg >/dev/null 2>&1; then
    use_rg="true"
  fi
  
  local matches="[]"
  local count=0
  
  if [ "$use_rg" = "true" ]; then
    # Use ripgrep
    local args=(--line-number --column --json)
    
    [ "$ignoreCase" = "true" ] && args+=(--ignore-case)
    [ "$regex" = "false" ] && args+=(--fixed-strings)
    [ "$recursive" = "false" ] && args+=(--max-depth 1)
    [ -n "$include" ] && args+=(--glob "$include")
    [ -n "$exclude" ] && args+=(--glob "!$exclude")
    
    args+=("$pattern")
    args+=("$path")
    
    local output
    output=$(rg "${args[@]}" 2>/dev/null | head -n "$maxResults")
    
    # Parse ripgrep JSON output
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      
      local type
      type=$(echo "$line" | jq -r '.type // empty')
      
      if [ "$type" = "match" ]; then
        local file
        local line_num
        local content
        local column
        
        file=$(echo "$line" | jq -r '.data.path.text // .data.path')
        line_num=$(echo "$line" | jq -r '.data.line_number')
        content=$(echo "$line" | jq -r '.data.lines.text')
        column=$(echo "$line" | jq -r '.data.submatches[0].start // 0')
        column=$((column + 1))
        
        local match
        match=$(jq -n \
          --arg file "$file" \
          --argjson line "$line_num" \
          --arg content "$content" \
          --argjson column "$column" \
          '{
            file: $file,
            line: $line,
            content: $content,
            column: $column
          }')
        
        matches=$(echo "$matches" | jq ". + [$match]")
        count=$((count + 1))
      fi
    done <<< "$output"
  else
    # Use grep as fallback
    local args=(-n)
    
    [ "$ignoreCase" = "true" ] && args+=(-i)
    [ "$regex" = "false" ] && args+=(-F)
    [ "$recursive" = "true" ] && args+=(-r)
    
    # Handle include/exclude via find if needed
    if [ -n "$include" ]; then
      # This is a simplified approach - full glob support is complex
      args+=(--include="$include")
    fi
    
    args+=("$pattern")
    args+=("$path")
    
    local output
    output=$(grep "${args[@]}" 2>/dev/null | head -n "$maxResults")
    
    # Parse grep output (format: file:line:content or line:content)
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      
      local file
      local line_num
      local content
      
      if [[ "$line" =~ ^(.+):([0-9]+):(.*)$ ]]; then
        file="${BASH_REMATCH[1]}"
        line_num="${BASH_REMATCH[2]}"
        content="${BASH_REMATCH[3]}"
      elif [[ "$line" =~ ^([0-9]+):(.*)$ ]]; then
        file="$path"
        line_num="${BASH_REMATCH[1]}"
        content="${BASH_REMATCH[2]}"
      else
        continue
      fi
      
      local match
      match=$(jq -n \
        --arg file "$file" \
        --argjson line "$line_num" \
        --arg content "$content" \
        '{
          file: $file,
          line: $line,
          content: $content,
          column: null
        }')
      
      matches=$(echo "$matches" | jq ". + [$match]")
      count=$((count + 1))
    done <<< "$output"
  fi
  
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
  tools_search_grep "$@"
fi
