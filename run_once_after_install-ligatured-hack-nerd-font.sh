#!/bin/bash
set -euo pipefail

# Builds the Hack+JetBrainsMono-ligature Nerd Font from
# https://github.com/gaplo917/Ligatured-Hack. That repo's own GitHub releases
# are stale, but its build pipeline always fetches whichever Nerd Fonts
# release is current at build time, so running it here (once, on a fresh
# machine) gets an up-to-date patched font rather than an old pinned one.
#
# Requires Docker (Rancher Desktop), which
# run_once_after_configure-rancher-desktop.sh starts headlessly just before
# this (chezmoi runs scripts in name order). If Docker still isn't ready,
# this exits non-zero — chezmoi retries run_once_ scripts that failed on
# every subsequent `chezmoi apply`, so re-running `chezmoi apply` once
# Rancher is up picks this back up.

export PATH="$HOME/.rd/bin:$PATH"
# Rancher runs with admin-access=false, so there's no /var/run/docker.sock;
# point at its socket directly, as ~/.envrc does (not loaded under chezmoi).
export DOCKER_HOST="unix://$HOME/.rd/docker.sock"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker not found (Rancher Desktop not installed yet?) — skipping font build, will retry on next chezmoi apply" >&2
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "docker daemon not reachable (Rancher Desktop not running yet?) — skipping font build, will retry on next chezmoi apply" >&2
  exit 1
fi

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

git clone --depth=1 --recursive --shallow-submodules \
  https://github.com/gaplo917/Ligatured-Hack.git "$workdir/Ligatured-Hack"

cd "$workdir/Ligatured-Hack"
mkdir -p fonts/nerd-fonts fonts/output
sh .travis/get-nerd-font.sh

# build.py reads the Mono variant from legacy "... Nerd Font Complete Mono.ttf"
# filenames, which in current Nerd Fonts releases lag behind the newer
# "HackNerdFontMono-*.ttf" files (missing recently-added custom icon glyphs,
# e.g. the Claude icon). Overwrite them with the fuller modern files so the
# ligatured output we actually install gets the complete glyph set.
for style in Regular Bold Italic "Bold Italic"; do
  modern_suffix=$(echo "$style" | tr -d ' ')
  cp "fonts/nerd-fonts/HackNerdFontMono-${modern_suffix}.ttf" "fonts/nerd-fonts/Hack ${style} Nerd Font Complete Mono.ttf"
done

docker build . -t ligatured-hack
docker run -v "$(pwd)/fonts/output:/usr/src/app/fonts/output" ligatured-hack

mkdir -p "$HOME/Library/Fonts"
cp fonts/output/HackNerdFontMonoJBMLigatured-Regular.ttf \
   fonts/output/HackNerdFontMonoJBMLigatured-Bold.ttf \
   fonts/output/HackNerdFontMonoJBMLigatured-Italic.ttf \
   fonts/output/HackNerdFontMonoJBMLigatured-BoldItalic.ttf \
   "$HOME/Library/Fonts/"

echo "Installed HackNerdFontMonoJBMLigatured. Restart apps using it (e.g. Ghostty) to pick up the new glyphs."
