#!/usr/bin/env bash
# POST prepared PNGs to Figma upload submit URLs and print name|imageHash|placedOnNodeId.
#
# Get the submit URLs from the Figma MCP `upload_assets` tool called with
# count=<N> and NO nodeId. That route commits the bytes into the file and each
# POST response returns a usable imageHash (the nodeId route did not reliably set
# fills). Pair each returned submitUrl with one of your image names, in order.
#
# Usage:  bash post_uploads.sh <submit_manifest.txt> <imgdir>
# Manifest: one "name|submitUrl" per line (name matches <imgdir>/<name>.png).
#
# Output (one line per image), capture this:
#   name|<imageHash>|<placedOnNodeId>
#   - imageHash       -> paint onto YOUR card frame: fills=[{type:"IMAGE",imageHash,scaleMode:"FILL"}]
#   - placedOnNodeId  -> throwaway auto-frame Figma created; delete it in use_figma
set -euo pipefail

manifest="${1:?usage: post_uploads.sh <submit_manifest.txt> <imgdir>}"
imgdir="${2:?usage: post_uploads.sh <submit_manifest.txt> <imgdir>}"

while IFS='|' read -r name url || [ -n "$name" ]; do
  name="$(printf '%s' "${name:-}" | xargs)"
  url="$(printf '%s' "${url:-}" | xargs)"
  [ -z "$name" ] && continue
  case "$name" in \#*) continue ;; esac
  [ -z "$url" ] && { echo "$name|ERROR|no-submit-url"; continue; }
  if [ ! -f "$imgdir/$name.png" ]; then echo "$name|ERROR|missing-png"; continue; fi

  resp=$(curl -s -X POST "$url" -F "file=@$imgdir/$name.png;type=image/png;filename=$name.png")
  hash=$(printf '%s' "$resp" | sed -n 's/.*"imageHash":"\([^"]*\)".*/\1/p')
  placed=$(printf '%s' "$resp" | sed -n 's/.*"placedOnNodeId":"\([^"]*\)".*/\1/p')
  echo "$name|${hash:-ERROR}|${placed:-}"
done < "$manifest"
