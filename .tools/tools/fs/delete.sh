#!/bin/bash
#
# FS Tool: delete - Delete files or directories (Shell Fallback)
#

tools_fs_delete() {
  local input
  local path
  local recursive
  local success="false"
  local existed="false"
  local error=""
  
  # Read input from stdin
  input=$(cat)
  path=$(echo "$input" | jq -r '.path // empty')
  recursive=$(echo "$input" | jq -r '.recursive // false')
  
  if [ -z "$path" ]; then
    echo '{"success":false,"path":"","existed":false,"error":"Missing required field: path"}'
    return 1
  fi
  
  # Check if exists
  if [ -e "$path" ]; then
    existed="true"
    
    if [ -d "$path" ]; then
      if [ "$recursive" = "true" ]; then
        rm -rf "$path" 2>/dev/null && success="true" || error="Failed to delete directory"
      else
        rmdir "$path" 2>/dev/null && success="true" || error="Directory not empty (use recursive=true)"
      fi
    else
      rm -f "$path" 2>/dev/null && success="true" || error="Failed to delete file"
    fi
  else
    # Doesn't exist - that's fine, operation is idempotent
    success="true"
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
  tools_fs_delete "$@"
fi
