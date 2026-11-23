#!/bin/bash
set -euo pipefail

# Sets Kiri up as the Docker runtime and waits for it to be ready, so Docker
# is available to later run_once_ scripts (e.g. the nerd font build) and for
# everyday use (kind, docker CLI) without a manual first-run step.
#
# `kiri setup --use` creates the `kiri` docker context and makes it current
# (in ~/.docker/config.json), installs the login launch agent that keeps the
# daemon running without a window, and starts it. There is no DOCKER_HOST to
# set: that would override the context.
#
# setup also appends its PATH line to ~/.zprofile, ~/.zshrc and ~/.bash_profile.
# Those PATH entries are managed in dot_zprofile instead, so the appended lines
# are stripped again, otherwise they'd show up as chezmoi drift.

KIRI="/Applications/Kiri.app/Contents/MacOS/kiri"

if [ ! -x "$KIRI" ]; then
  echo "kiri not found (Kiri not installed yet?) -- skipping, will retry on next chezmoi apply" >&2
  exit 1
fi

# Backgrounded with its output in a file: setup leaves a detached daemon behind
# that inherits stdout, so a caller reading the pipe (a `| tail`, or chezmoi
# capturing output) would wait on it forever, and a re-run can hang after it has
# printed everything. Readiness is polled below instead of trusting its exit.
log=$(mktemp)
"$KIRI" setup --use >"$log" 2>&1 </dev/null &
setup_pid=$!

ready=false
for _ in $(seq 1 60); do
  if env -u DOCKER_HOST "$HOME/.kiri/bin/docker" info >/dev/null 2>&1; then
    ready=true
    break
  fi
  sleep 5
done

kill "$setup_pid" 2>/dev/null || true

for rc in "$HOME/.zprofile" "$HOME/.zshrc" "$HOME/.bash_profile"; do
  [ -f "$rc" ] || continue
  # Drops the comment and the PATH line after it, then the blank lines setup left before them.
  sed -i '' -e '/^# Added by Kiri:/,+1d' "$rc"
  sed -i '' -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$rc"
  # ~/.bash_profile only exists because setup creates it; nothing else uses bash here.
  if [ "$rc" = "$HOME/.bash_profile" ] && [ -z "$(tr -d '[:space:]' < "$rc")" ]; then
    rm "$rc"
  fi
done

if [ "$ready" = true ]; then
  rm -f "$log"
  exit 0
fi

cat "$log" >&2
rm -f "$log"
echo "Kiri did not become ready within 5 minutes -- will retry on next chezmoi apply" >&2
exit 1
