#!/bin/bash
set -euo pipefail

eval "$(fnm env --shell bash)"

fnm install --lts
fnm default lts-latest
