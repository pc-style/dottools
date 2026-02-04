#!/bin/bash
#
# Git Tool: branch - Manage branches (Shell Fallback)
#

tools_git_branch() {
  local input
  local path
  local list
  local create
  local from
  local switchTo
  local deleteBranch
  local force
  
  # Read input from stdin
  input=$(cat)
  path=$(echo "$input" | jq -r '.path // "."')
  list=$(echo "$input" | jq -r '.list // true')
  create=$(echo "$input" | jq -r '.create // empty')
  from=$(echo "$input" | jq -r '.from // empty')
  switchTo=$(echo "$input" | jq -r '.switch // empty')
  deleteBranch=$(echo "$input" | jq -r '.delete // empty')
  force=$(echo "$input" | jq -r '.force // false')
  
  # Handle create branch
  if [ -n "$create" ]; then
    local args=("-C" "$path" "checkout" "-b" "$create")
    [ -n "$from" ] && args+=("$from")
    
    git "${args[@]}" 2>/dev/null
    if [ $? -eq 0 ]; then
      echo '{"success":true}'
    else
      echo '{"success":false,"error":"Failed to create branch"}'
    fi
    return 0
  fi
  
  # Handle switch branch
  if [ -n "$switchTo" ]; then
    git -C "$path" checkout "$switchTo" 2>/dev/null
    if [ $? -eq 0 ]; then
      echo '{"success":true}'
    else
      echo '{"success":false,"error":"Failed to switch branch"}'
    fi
    return 0
  fi
  
  # Handle delete branch
  if [ -n "$deleteBranch" ]; then
    local flag="-d"
    [ "$force" = "true" ] && flag="-D"
    
    git -C "$path" branch "$flag" "$deleteBranch" 2>/dev/null
    if [ $? -eq 0 ]; then
      echo '{"success":true}'
    else
      echo '{"success":false,"error":"Failed to delete branch"}'
    fi
    return 0
  fi
  
  # List branches
  local output
  output=$(git -C "$path" branch -vv 2>/dev/null)
  
  if [ $? -ne 0 ]; then
    echo '{"success":false,"branches":[],"error":"Failed to list branches"}'
    return 1
  fi
  
  local branches="[]"
  local current=""
  
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    
    local isCurrent="false"
    local name=""
    local remote=""
    local ahead=0
    local behind=0
    
    # Check if current branch
    if [[ "$line" == \** ]]; then
      isCurrent="true"
      line="${line:2}"
      name=$(echo "$line" | awk '{print $1}')
      current="$name"
    else
      line="${line:2}"
      name=$(echo "$line" | awk '{print $1}')
    fi
    
    # Extract remote and tracking info
    if [[ "$line" =~ \[([a-zA-Z0-9/_-]+)\] ]]; then
      remote="${BASH_REMATCH[1]}"
      
      if [[ "$line" =~ ahead\ ([0-9]+) ]]; then
        ahead="${BASH_REMATCH[1]}"
      fi
      if [[ "$line" =~ behind\ ([0-9]+) ]]; then
        behind="${BASH_REMATCH[1]}"
      fi
    fi
    
    local branch_obj
    branch_obj=$(jq -n \
      --arg name "$name" \
      --argjson isCurrent "$isCurrent" \
      --arg remote "$remote" \
      --argjson ahead "$ahead" \
      --argjson behind "$behind" \
      '{
        name: $name,
        current: $isCurrent,
        remote: (if $remote == "" then null else $remote end),
        ahead: (if $ahead == 0 then null else $ahead end),
        behind: (if $behind == 0 then null else $behind end)
      }')
    
    branches=$(echo "$branches" | jq ". + [$branch_obj]")
  done <<< "$output"
  
  jq -n \
    --argjson success "true" \
    --arg current "$current" \
    --argjson branches "$branches" \
    '{
      success: $success,
      current: $current,
      branches: $branches
    }'
}

# Allow direct execution
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  tools_git_branch "$@"
fi
