#!/usr/bin/env bash
#
# Claude Code statusLine command.
#
# Adapted from the krak3n zsh-theme used in this user's ~/.zshrc
# (~/.zgen/krak3n/zsh-theme-master/krak3n.zsh-theme), which does not
# define a bash-style PS1 but instead a zsh PROMPT built from:
#   - kubectl context
#   - user / current directory
#   - go version (inside Go projects)
#   - git branch / dirty state
#

input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir')

# Colours (matching the 256-colour palette used by the krak3n zsh-theme)
BLUE=$'\033[38;5;4m'
YELLOW=$'\033[38;5;3m'
GREY=$'\033[38;5;8m'
RED=$'\033[38;5;1m'
RESET=$'\033[0m'
ORANGE=$'\033[38;2;217;119;87m'

CLAUDE_USAGE_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/claude-usage"
CLAUDE_USAGE_LOCK="${XDG_CACHE_HOME:-$HOME/.cache}/claude-usage.lock"
CLAUDE_USAGE_TTL=600

out=""

# Kubernetes context
if command -v kubectl >/dev/null 2>&1; then
  kctx=$(kubectl config current-context 2>/dev/null)
  if [ -n "$kctx" ]; then
    out="${out}${BLUE}󰠳${RESET} ${GREY}${kctx}${RESET}  "
  fi
fi

# User / current directory
out="${out}${BLUE}${RESET} $(whoami) ${YELLOW}${RESET} $(basename "$cwd")"

# Go version (only shown inside a Go project)
if command -v go >/dev/null 2>&1; then
  d="$cwd"
  while [ "$d" != "/" ] && [ ! -f "$d/go.mod" ]; do
    d=$(dirname "$d")
  done
  if [ -f "$d/go.mod" ]; then
    ver=$(go version | awk '{print $3}' | sed 's/^go//')
    out="${out}  ${BLUE}${RESET} ${ver}"
  fi
fi

# Claude usage (session/week %), shared cache with the krak3n zsh-theme so
# both consumers refresh it async and never block on the ~2.5s API call
if command -v claude >/dev/null 2>&1; then
  mkdir -p "$(dirname "$CLAUDE_USAGE_CACHE")"
  now=$(date +%s)
  cache_mtime=0
  [ -f "$CLAUDE_USAGE_CACHE" ] && cache_mtime=$(date -r "$CLAUDE_USAGE_CACHE" +%s 2>/dev/null || echo 0)
  if [ $((now - cache_mtime)) -gt "$CLAUDE_USAGE_TTL" ]; then
    lock_mtime=0
    [ -f "$CLAUDE_USAGE_LOCK" ] && lock_mtime=$(date -r "$CLAUDE_USAGE_LOCK" +%s 2>/dev/null || echo 0)
    if [ $((now - lock_mtime)) -gt 120 ]; then
      touch "$CLAUDE_USAGE_LOCK"
      (
        result=$(claude -p "/usage" 2>/dev/null)
        session=$(echo "$result" | sed -n 's/.*Current session: \([0-9]*\)%.*/\1/p')
        week=$(echo "$result" | sed -n 's/.*Current week[^:]*: \([0-9]*\)%.*/\1/p')
        if [ -n "$session" ] && [ -n "$week" ]; then
          echo "$session $week" > "$CLAUDE_USAGE_CACHE"
        fi
        rm -f "$CLAUDE_USAGE_LOCK"
      ) &
      disown
    fi
  fi
  if [ -f "$CLAUDE_USAGE_CACHE" ]; then
    read -r usage_session usage_week < "$CLAUDE_USAGE_CACHE"
    if [ -n "$usage_session" ]; then
      out="${out}  ${ORANGE}${RESET} ${GREY}${usage_session}%/${usage_week}%${RESET}"
    fi
  fi
fi

# Git branch + dirty state
if command -v git >/dev/null 2>&1 && git -C "$cwd" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  ref=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  if [ -n "$ref" ]; then
    dirty=""
    if [ -n "$(git -C "$cwd" --no-optional-locks status --porcelain --ignore-submodules 2>/dev/null)" ]; then
      dirty=" ${RED}${RESET}"
    fi
    out="${out}  ${BLUE}${RESET} ${YELLOW}${ref}${RESET}${dirty}"
  fi
fi

printf '%s\n' "$out"
