#!/bin/bash
set -euo pipefail

ZGEN_DIR="${ZGEN_DIR:-$HOME/.zgen}"

if [ -d "$ZGEN_DIR" ]; then
  exit 0
fi

git clone --depth=1 https://github.com/tarjoilija/zgen.git "$ZGEN_DIR"
