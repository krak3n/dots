#!/bin/bash
set -euo pipefail

# Starts Rancher Desktop headlessly (no window, no sudo password prompt)
# so Docker is ready for later run_once_ scripts (e.g. the nerd font
# build) and for everyday use (kind, docker CLI) without a manual
# first-run step.
#
# --application.admin-access=false skips the sudo-requiring setup
# (external routable IP + /var/run/docker.sock symlink) -- neither of
# which we need, since DOCKER_HOST already points at ~/.rd/docker.sock
# directly (see ~/.envrc). Confirmed working headless with this flag
# combination; the privileged bits are opt-in extras, not a hard
# dependency of the vz backend used here.

RDCTL="$HOME/.rd/bin/rdctl"

if [ ! -x "$RDCTL" ]; then
  echo "rdctl not found (Rancher Desktop not installed yet?) -- skipping, will retry on next chezmoi apply" >&2
  exit 1
fi

"$RDCTL" start \
  --no-modal-dialogs \
  --application.start-in-background \
  --application.admin-access=false

for _ in $(seq 1 60); do
  if DOCKER_HOST="unix://$HOME/.rd/docker.sock" docker info >/dev/null 2>&1; then
    exit 0
  fi
  sleep 5
done

echo "Rancher Desktop did not become ready within 5 minutes -- will retry on next chezmoi apply" >&2
exit 1
