#!/bin/bash
set -euo pipefail

FONT_DIR="$HOME/Library/Fonts"
RELEASE_URL="https://github.com/gaplo917/Ligatured-Hack/releases/download/v3.003%2BNv2.1.0%2BFC%2BJBMv2.242/HackLigatured-v3.003%2BFC3.1%2BJBMv2.242.zip"
STYLES=(Regular Bold Italic BoldItalic)

if [ -f "$FONT_DIR/HackNerdFontMonoJBMLigatured-Regular.ttf" ]; then
  exit 0
fi

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

curl -sL -o "$TMPDIR/font.zip" "$RELEASE_URL"

FILES=()
for style in "${STYLES[@]}"; do
  FILES+=("HackNerdFontMonoJBMLigatured-$style.ttf")
done

unzip -o -j "$TMPDIR/font.zip" "${FILES[@]}" -d "$TMPDIR"

mkdir -p "$FONT_DIR"
cp "${FILES[@]/#/$TMPDIR/}" "$FONT_DIR/"
