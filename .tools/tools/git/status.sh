#!/bin/bash
#
# Git Tool: status - Get git repository status (Shell Fallback)
#

tools_git_status() {
  local input
  local path
  local isRepo="false"
  local branch=""
  local isClean="true"
  local modified="[]"
  local untracked="[]"
  local staged="[]"
  local deleted="[]"
  local renamed="[]"
  local ahead="null"
  local behind="null"
  
  # Read input from stdin
  input=$(cat)
  path=$(echo "$input" | jq -r '.path // "."')
  
  # Check if git repo
  if ! git -C "$path" rev-parse --git-dir > /dev/null 2>&1; then
    jq -n \
      --argjson isRepo "$isRepo" \
      --arg branch "$branch" \
      --argjson isClean "$isClean" \
      --argjson modified "$modified" \
      --argjson untracked "$untracked" \
      --argjson staged "$staged" \
      --argjson deleted "$deleted" \
      --argjson renamed "$renamed" \
      '{
        isRepo: $isRepo,
        branch: $branch,
        isClean: $isClean,
        modified: $modified,
        untracked: $untracked,
        staged: $staged,
        deleted: $deleted,
        renamed: $renamed
      }'
    return 0
  fi
  
  isRepo="true"
  
  # Get current branch
  branch=$(git -C "$path" branch --show-current 2>/dev/null || echo "HEAD")
  
  # Get status
  local status_text
  status_text=$(git -C "$path" status --porcelain 2>/dev/null || echo "")
  
  # Parse status
  local mod_arr="[]"
  local unt_arr="[]"
  local stg_arr="[]"
  local del_arr="[]"
  local ren_arr="[]"
  
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    
    local xy="${line:0:2}"
    local rest="${line:3}"
    
    if [ "$xy" = "??" ]; then
      unt_arr=$(echo "$unt_arr" | jq ". + [\"$rest\"]")
    else
      # Staged
      case "${xy:0:1}" in
        M|A)
          stg_arr=$(echo "$stg_arr" | jq ". + [\"$rest\"]")
          ;;
        D)
          stg_arr=$(echo "$stg_arr" | jq ". + [\"$rest\"]")
          ;;
        R)
          local old new
          old=$(echo "$rest" | cut -d' ' -f1)
          new=$(echo "$rest" | cut -d' ' -f2)
          ren_arr=$(echo "$ren_arr" | jq ". + [{\"old\":\"$old\",\"new\":\"$new\"}]")
          ;;
      esac
      
      # Unstaged
      case "${xy:1:1}" in
        M)
          mod_arr=$(echo "$mod_arr" | jq ". + [\"$rest\"]")
          ;;
        D)
          del_arr=$(echo "$del_arr" | jq ". + [\"$rest\"]")
          ;;
      esac
    fi
  done <<< "$status_text"
  
  # Check if clean
  local total_mod total_unt total_stg total_del total_ren
  total_mod=$(echo "$mod_arr" | jq 'length')
  total_unt=$(echo "$unt_arr" | jq 'length')
  total_stg=$(echo "$stg_arr" | jq 'length')
  total_del=$(echo "$del_arr" | jq 'length')
  total_ren=$(echo "$ren_arr" | jq 'length')
  
  if [ "$total_mod" -gt 0 ] || [ "$total_unt" -gt 0 ] || [ "$total_stg" -gt 0 ] || [ "$total_del" -gt 0 ] || [ "$total_ren" -gt 0 ]; then
    isClean="false"
  fi
  
  jq -n \
    --argjson isRepo "$isRepo" \
    --arg branch "$branch" \
    --argjson isClean "$isClean" \
    --argjson modified "$mod_arr" \
    --argjson untracked "$unt_arr" \
    --argjson staged "$stg_arr" \
    --argjson deleted "$del_arr" \
    --argjson renamed "$ren_arr" \
    '{
      isRepo: $isRepo,
      branch: $branch,
      isClean: $isClean,
      modified: $modified,
      untracked: $untracked,
      staged: $staged,
      deleted: $deleted,
      renamed: $renamed
    }'
}

# Allow direct execution
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  tools_git_status "$@"
fi
