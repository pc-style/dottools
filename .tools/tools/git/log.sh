#!/bin/bash
#
# Git Tool: log - Get commit history (Shell Fallback)
#

tools_git_log() {
  local input
  local path
  local limit
  local file
  local stat
  local format
  
  # Read input from stdin
  input=$(cat)
  path=$(echo "$input" | jq -r '.path // "."')
  limit=$(echo "$input" | jq -r '.limit // 10')
  file=$(echo "$input" | jq -r '.file // empty')
  stat=$(echo "$input" | jq -r '.stat // false')
  
  # Build git log command
  local args=("-C" "$path" "log" "--max-count=$limit" "--pretty=format:%H|%h|%an|%ae|%ai|%s")
  
  if [ "$stat" = "true" ]; then
    args+=("--name-only")
  fi
  
  if [ -n "$file" ]; then
    args+=("--" "$file")
  fi
  
  local output
  output=$(git "${args[@]}" 2>/dev/null)
  
  if [ $? -ne 0 ]; then
    echo '{"success":false,"commits":[],"error":"Failed to get log"}'
    return 1
  fi
  
  # Parse commits
  local commits="[]"
  local current_commit=""
  local current_files="[]"
  
  while IFS= read -r line; do
    if [[ "$line" =~ ^[a-f0-9]{40}\| ]]; then
      # Save previous commit if exists
      if [ -n "$current_commit" ]; then
        local commit_with_files
        if [ "$stat" = "true" ]; then
          commit_with_files=$(echo "$current_commit" | jq --argjson files "$current_files" '. + {files: $files}')
        else
          commit_with_files="$current_commit"
        fi
        commits=$(echo "$commits" | jq ". + [$commit_with_files]")
      fi
      
      # Parse new commit
      IFS='|' read -r hash shortHash author email date message <<< "$line"
      current_commit=$(jq -n \
        --arg hash "$hash" \
        --arg shortHash "$shortHash" \
        --arg author "$author" \
        --arg email "$email" \
        --arg date "$date" \
        --arg message "$message" \
        '{
          hash: $hash,
          shortHash: $shortHash,
          author: $author,
          email: $email,
          date: $date,
          message: $message
        }')
      current_files="[]"
    elif [ -n "$line" ] && [ "$stat" = "true" ] && [ -n "$current_commit" ]; then
      current_files=$(echo "$current_files" | jq ". + [\"$line\"]")
    fi
  done <<< "$output"
  
  # Add last commit
  if [ -n "$current_commit" ]; then
    local commit_with_files
    if [ "$stat" = "true" ]; then
      commit_with_files=$(echo "$current_commit" | jq --argjson files "$current_files" '. + {files: $files}')
    else
      commit_with_files="$current_commit"
    fi
    commits=$(echo "$commits" | jq ". + [$commit_with_files]")
  fi
  
  local count
  count=$(echo "$commits" | jq 'length')
  
  jq -n \
    --argjson success "true" \
    --argjson commits "$commits" \
    --argjson count "$count" \
    '{
      success: $success,
      commits: $commits,
      total: $count
    }'
}

# Allow direct execution
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  tools_git_log "$@"
fi
