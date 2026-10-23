#!/bin/bash
set -euo pipefail

eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(fnm env --shell bash)"

fnm install --lts
fnm default lts-latest
