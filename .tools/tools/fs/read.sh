#!/bin/bash
#
# FS Tool: read - Read file contents (Shell Fallback)
#

tools_fs_read() {
  local input
  local path
  local encoding
  local content
  local size
  local modified
  local exists="false"
  
  # Read input from stdin
  input=$(cat)
  path=$(echo "$input" | jq -r '.path // empty')
  encoding=$(echo "$input" | jq -r '.encoding // "utf8"')
  
  if [ -z "$path" ]; then
    echo '{"error":"Missing required field: path"}'
    return 1
  fi
  
  if [ ! -f "$path" ]; then
    echo '{"content":"","size":0,"exists":false}'
    return 0
  fi
  
  exists="true"
  
  if [ "$encoding" = "base64" ]; then
    content=$(base64 -i "$path" 2>/dev/null || base64 "$path" 2>/dev/null || echo "")
  else
    content=$(cat "$path")
  fi
  
  size=${#content}
  
  # Get modification time
  if command -v stat >/dev/null 2>&1; then
    if stat -f%m "$path" >/dev/null 2>&1; then
      # macOS stat
      modified=$(stat -f%m "$path")
      modified=$((modified * 1000))
    else
      # Linux stat
      modified=$(stat -c%Y "$path")
      modified=$((modified * 1000))
    fi
  fi
  
  # Escape content for JSON
  content_escaped=$(printf '%s' "$content" | jq -Rs '.')
  
  jq -n \
    --argjson content "$content_escaped" \
    --argjson size "$size" \
    --argjson exists "$exists" \
    --argjson modified "${modified:-null}" \
    '{
      content: $content,
      size: $size,
      exists: $exists,
      modified: $modified
    }'
}

# Allow direct execution
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  tools_fs_read "$@"
fi
