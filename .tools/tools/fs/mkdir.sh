#!/bin/bash
#
# FS Tool: mkdir - Create directories (Shell Fallback)
#

tools_fs_mkdir() {
  local input
  local path
  local recursive
  local success="false"
  local existed="false"
  local error=""
  
  # Read input from stdin
  input=$(cat)
  path=$(echo "$input" | jq -r '.path // empty')
  recursive=$(echo "$input" | jq -r '.recursive // true')
  
  if [ -z "$path" ]; then
    echo '{"success":false,"path":"","existed":false,"error":"Missing required field: path"}'
    return 1
  fi
  
  # Check if already exists
  if [ -d "$path" ]; then
    existed="true"
    success="true"
  else
    # Check if exists but is a file
    if [ -e "$path" ]; then
      existed="true"
      error="Path exists but is not a directory"
    else
      # Create directory
      if [ "$recursive" = "true" ]; then
        mkdir -p "$path" 2>/dev/null && success="true" || error="Failed to create directory"
      else
        mkdir "$path" 2>/dev/null && success="true" || error="Failed to create directory"
      fi
    fi
  fi
  
  if [ "$success" = "true" ]; then
    jq -n \
      --arg path "$path" \
      --argjson existed "$existed" \
      --argjson success "$success" \
      '{
        success: $success,
        path: $path,
        existed: $existed
      }'
  else
    jq -n \
      --arg path "$path" \
      --argjson existed "$existed" \
      --argjson success "$success" \
      --arg error "$error" \
      '{
        success: $success,
        path: $path,
        existed: $existed,
        error: $error
      }'
  fi
}

# Allow direct execution
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  tools_fs_mkdir "$@"
fi
