#!/usr/bin/env bash
# Download reference images and convert them to PNG.
#
# WHY PNG: Figma accepts WebP uploads (returns HTTP 200 + an imageHash) but does
# NOT render WebP image fills — the frame shows up blank. Mobbin returns WebP by
# default, so every image must be converted before it goes into Figma.
#
# Usage:  bash prepare_images.sh <manifest.txt> <outdir>
# Manifest: one "name|url" per line. Blank lines and lines starting with # are skipped.
#   name becomes <outdir>/<name>.png  (use descriptive names, e.g. A_whatsapp_voice)
set -euo pipefail

manifest="${1:?usage: prepare_images.sh <manifest.txt> <outdir>}"
outdir="${2:?usage: prepare_images.sh <manifest.txt> <outdir>}"
mkdir -p "$outdir"

to_png() {  # <src> <out> -> 0 on success
  local src="$1" out="$2"
  if command -v sips  >/dev/null 2>&1; then sips -s format png "$src" --out "$out" >/dev/null 2>&1 && return 0; fi
  if command -v magick >/dev/null 2>&1; then magick "$src" "$out"        >/dev/null 2>&1 && return 0; fi
  if command -v convert>/dev/null 2>&1; then convert "$src" "$out"       >/dev/null 2>&1 && return 0; fi
  if command -v dwebp  >/dev/null 2>&1; then dwebp "$src" -o "$out"      >/dev/null 2>&1 && return 0; fi
  return 1
}

dims_of() {  # <png> -> "W H" (empty if unknown)
  if command -v sips >/dev/null 2>&1; then
    sips -g pixelWidth -g pixelHeight "$1" 2>/dev/null | awk '/pixelWidth/{w=$2}/pixelHeight/{h=$2}END{if(w&&h)print w" "h}'
  elif command -v magick >/dev/null 2>&1; then
    magick identify -format '%w %h' "$1" 2>/dev/null
  fi
}

: > "$outdir/dims.tsv"   # name<TAB>width<TAB>height — used to size cards without cropping
ok=0; fail=0
while IFS='|' read -r name url || [ -n "$name" ]; do
  name="$(printf '%s' "${name:-}" | xargs)"
  url="$(printf '%s' "${url:-}" | xargs)"
  [ -z "$name" ] && continue
  case "$name" in \#*) continue ;; esac
  [ -z "$url" ] && { echo "SKIP  $name (no url)"; continue; }

  if ! curl -sL "$url" -o "$outdir/$name.src"; then
    echo "FAIL  $name (download)"; fail=$((fail+1)); continue
  fi
  if to_png "$outdir/$name.src" "$outdir/$name.png"; then
    kb=$(( $(wc -c < "$outdir/$name.png") / 1024 ))
    dims="$(dims_of "$outdir/$name.png")"
    w="${dims% *}"; h="${dims#* }"
    [ -n "$dims" ] && printf '%s\t%s\t%s\n' "$name" "$w" "$h" >> "$outdir/dims.tsv"
    echo "OK    $name  ${dims:-?x?}  ${kb}KB"; ok=$((ok+1))
  else
    echo "FAIL  $name (convert — no image tool, or URL was not an image)"; fail=$((fail+1))
  fi
  rm -f "$outdir/$name.src"
done < "$manifest"

echo "---"
echo "prepared $ok PNG(s) in $outdir  (failures: $fail)"
echo "dimensions written to $outdir/dims.tsv  (name<TAB>width<TAB>height)"
[ "$fail" -eq 0 ]
