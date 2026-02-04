#!/bin/bash
#
# Git Tool: commit - Create a git commit (Shell Fallback)
#

tools_git_commit() {
  local input
  local path
  local message
  local all
  local files
  local success="false"
  local hash=""
  local error=""
  
  # Read input from stdin
  input=$(cat)
  path=$(echo "$input" | jq -r '.path // "."')
  message=$(echo "$input" | jq -r '.message // empty')
  all=$(echo "$input" | jq -r '.all // false')
  files=$(echo "$input" | jq -r '.files // empty')
  
  if [ -z "$message" ]; then
    echo '{"success":false,"error":"Missing required field: message"}'
    return 1
  fi
  
  # Stage files if needed
  if [ "$all" = "true" ]; then
    git -C "$path" add -A 2>/dev/null || {
      echo '{"success":false,"error":"Failed to stage files"}'
      return 1
    }
  elif [ -n "$files" ]; then
    # Parse files array
    local file_list
    file_list=$(echo "$files" | jq -r '.[]')
    if [ -n "$file_list" ]; then
      git -C "$path" add $file_list 2>/dev/null || {
        echo '{"success":false,"error":"Failed to stage files"}'
        return 1
      }
    fi
  fi
  
  # Create commit
  local output
  output=$(git -C "$path" commit -m "$message" 2>&1) && success="true" || error="$output"
  
  if [ "$success" = "true" ]; then
    # Extract commit hash
    hash=$(echo "$output" | grep -oE '\[.+ [a-f0-9]+\]' | grep -oE '[a-f0-9]+' || echo "")
    
    if [ -n "$hash" ]; then
      jq -n \
        --argjson success "$success" \
        --arg hash "$hash" \
        '{
          success: $success,
          hash: $hash
        }'
    else
      jq -n \
        --argjson success "$success" \
        '{
          success: $success
        }'
    fi
  else
    error_escaped=$(echo "$error" | jq -Rs '.')
    jq -n \
      --argjson success "$success" \
      --arg error "$error_escaped" \
      '{
        success: $success,
        error: $error
      }'
  fi
}

# Allow direct execution
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  tools_git_commit "$@"
fi
