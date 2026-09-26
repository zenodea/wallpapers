#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if command -v magick >/dev/null; then IM=(magick)
elif command -v convert >/dev/null; then IM=(convert)
else echo "ImageMagick is required (brew install imagemagick / apt install imagemagick)" >&2; exit 1
fi

W=480 H=270 COLS=3 SRC=full-size
mkdir -p previews

files=()
while IFS= read -r f; do files+=("$f"); done < <(ls "$SRC" | grep -iE '^[0-9]+-.*\.(png|jpe?g|webp|avif)$' | sort -n)

for f in "${files[@]}"; do
  out="previews/${f%.*}.jpg"
  [[ -f "$out" && "$out" -nt "$SRC/$f" ]] && continue
  echo "preview: $f"
  "${IM[@]}" "$SRC/${f}[0]" -auto-orient -thumbnail "${W}x${H}^" -gravity center -extent "${W}x${H}" \
    -colorspace sRGB -quality 78 -interlace JPEG "$out"
done

for p in previews/*.jpg; do
  stem=$(basename "${p%.jpg}")
  ls "$SRC/$stem".* >/dev/null 2>&1 || { echo "removed: $p"; rm "$p"; }
done

{
  echo "# wallpapers"
  echo
  echo "<table>"
  for i in "${!files[@]}"; do
    f=${files[$i]}; stem=${f%.*}; num=${stem%%-*}; name=${stem#*-}; name=${name//-/ }
    (( i % COLS == 0 )) && echo "<tr>"
    echo "<td align=\"center\" width=\"33%\"><a href=\"$SRC/$f\"><img src=\"previews/$stem.jpg\" alt=\"$name\"></a><br><sub>$num · $name</sub></td>"
    (( i % COLS == COLS - 1 || i == ${#files[@]} - 1 )) && echo "</tr>"
  done
  echo "</table>"
} > README.md

echo "README.md: ${#files[@]} wallpapers"
