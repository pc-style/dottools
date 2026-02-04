#!/bin/bash
#
# Search Tool: find - Find files by name or pattern (Shell Fallback)
#

tools_search_find() {
  local input
  local path
  local name
  local pattern
  local type
  local maxDepth
  local minSize
  local maxSize
  local modifiedAfter
  local modifiedBefore
  
  # Read input from stdin
  input=$(cat)
  path=$(echo "$input" | jq -r '.path // "."')
  name=$(echo "$input" | jq -r '.name // empty')
  pattern=$(echo "$input" | jq -r '.pattern // empty')
  type=$(echo "$input" | jq -r '.type // empty')
  maxDepth=$(echo "$input" | jq -r '.maxDepth // 999')
  minSize=$(echo "$input" | jq -r '.minSize // empty')
  maxSize=$(echo "$input" | jq -r '.maxSize // empty')
  modifiedAfter=$(echo "$input" | jq -r '.modifiedAfter // empty')
  modifiedBefore=$(echo "$input" | jq -r '.modifiedBefore // empty')
  
  # Build find command
  local args=("$path" -maxdepth "$maxDepth")
  
  # Type filter
  if [ "$type" = "f" ]; then
    args+=(-type f)
  elif [ "$type" = "d" ]; then
    args+=(-type d)
  fi
  
  # Name filter
  if [ -n "$name" ]; then
    args+=(-name "$name")
  fi
  
  # Pattern filter (regex on name)
  if [ -n "$pattern" ]; then
    # Convert pattern to find regex
    args+=(-regex ".*/${pattern}")
  fi
  
  # Size filters
  if [ -n "$minSize" ]; then
    args+=(-size "+${minSize}c")
  fi
  if [ -n "$maxSize" ]; then
    args+=(-size "-${maxSize}c")
  fi
  
  # Modified time filters
  if [ -n "$modifiedAfter" ]; then
    local after_secs
    after_secs=$((modifiedAfter / 1000))
    args+=(-newermt "@${after_secs}")
  fi
  if [ -n "$modifiedBefore" ]; then
    local before_secs
    before_secs=$((modifiedBefore / 1000))
    args+=(! -newermt "@${before_secs}")
  fi
  
  # Execute find
  local files_output
  files_output=$(find "${args[@]}" 2>/dev/null | sort)
  
  local files="[]"
  local count=0
  
  while IFS= read -r file_path; do
    [ -z "$file_path" ] && continue
    
    local filename
    local size
    local is_dir
    local modified
    
    filename=$(basename "$file_path")
    
    if [ -d "$file_path" ]; then
      is_dir="true"
      size=0
    else
      is_dir="false"
      if stat -f%z "$file_path" >/dev/null 2>&1; then
        size=$(stat -f%z "$file_path")
      else
        size=$(stat -c%s "$file_path" 2>/dev/null || echo "0")
      fi
    fi
    
    if stat -f%m "$file_path" >/dev/null 2>&1; then
      # macOS
      modified=$(stat -f%m "$file_path")
      modified=$((modified * 1000))
    else
      # Linux
      modified=$(stat -c%Y "$file_path" 2>/dev/null || echo "0")
      modified=$((modified * 1000))
    fi
    
    local file_obj
    file_obj=$(jq -n \
      --arg path "$file_path" \
      --arg name "$filename" \
      --argjson size "$size" \
      --argjson isDirectory "$is_dir" \
      --argjson modified "$modified" \
      '{
        path: $path,
        name: $name,
        size: $size,
        isDirectory: $isDirectory,
        modified: $modified
      }')
    
    files=$(echo "$files" | jq ". + [$file_obj]")
    count=$((count + 1))
  done <<< "$files_output"
  
  jq -n \
    --argjson success "true" \
    --argjson files "$files" \
    --argjson count "$count" \
    '{
      success: $success,
      files: $files,
      count: $count
    }'
}

# Allow direct execution
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  tools_search_find "$@"
fi
