#!/bin/bash
set -euo pipefail

export GOROOT="${GOROOT:-$HOME/.go}"
export GOPATH="${GOPATH:-$HOME/go}"
export PATH="$GOPATH/bin:$PATH"
BIN="$GOPATH/bin/g"

if [ ! -f "$BIN" ]; then
  mkdir -p "$GOPATH/bin"
  curl -fsSL -o "$BIN" "https://github.com/stefanmaric/g/releases/latest/download/g"
  chmod +x "$BIN"
fi

"$BIN" install latest
