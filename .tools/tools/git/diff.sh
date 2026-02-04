#!/bin/bash
#
# Git Tool: diff - Get diff between commits or working tree (Shell Fallback)
#

tools_git_diff() {
  local input
  local path
  local from
  local to
  local file
  local success="false"
  local diff=""
  local hasChanges="false"
  local filesChanged=0
  local error=""
  
  # Read input from stdin
  input=$(cat)
  path=$(echo "$input" | jq -r '.path // "."')
  from=$(echo "$input" | jq -r '.from // "HEAD"')
  to=$(echo "$input" | jq -r '.to // empty')
  file=$(echo "$input" | jq -r '.file // empty')
  
  # Build git diff command
  local args=("-C" "$path" "diff")
  
  if [ -n "$to" ]; then
    args+=("${from}..${to}")
  elif [ "$from" != "WORKING" ]; then
    args+=("$from")
  fi
  
  if [ -n "$file" ]; then
    args+=("--" "$file")
  fi
  
  # Execute git diff
  diff=$(git "${args[@]}" 2>&1) && success="true" || error="$diff"
  
  if [ "$success" = "true" ]; then
    if [ -n "$diff" ]; then
      hasChanges="true"
      filesChanged=$(echo "$diff" | grep -c "^diff --git" || echo "0")
    fi
    
    # Escape diff for JSON
    diff_escaped=$(echo "$diff" | jq -Rs '.')
    
    jq -n \
      --argjson success "$success" \
      --argjson diff "$diff_escaped" \
      --argjson hasChanges "$hasChanges" \
      --argjson filesChanged "$filesChanged" \
      '{
        success: $success,
        diff: $diff,
        hasChanges: $hasChanges,
        filesChanged: $filesChanged
      }'
  else
    error_escaped=$(echo "$error" | jq -Rs '.')
    jq -n \
      --argjson success "$success" \
      --argjson diff '""' \
      --argjson hasChanges "$hasChanges" \
      --argjson filesChanged "$filesChanged" \
      --arg error "$error_escaped" \
      '{
        success: $success,
        diff: $diff,
        hasChanges: $hasChanges,
        filesChanged: $filesChanged,
        error: $error
      }'
  fi
}

# Allow direct execution
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  tools_git_diff "$@"
fi
