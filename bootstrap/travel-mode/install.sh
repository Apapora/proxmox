#!/usr/bin/env bash
# install.sh — push travel-mode scripts + network config files to PVE host.
# Idempotent: safe to re-run after edits.
#
# Run from your workstation:
#   cd bootstrap/travel-mode && ./install.sh
#
# Assumes ~/.ssh/config has `Host pve` aliased to root@10.0.0.19.

set -euo pipefail

PVE_HOST="${PVE_HOST:-pve}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$SCRIPT_DIR"

echo "==> Ensuring target dirs exist on $PVE_HOST"
ssh "$PVE_HOST" 'install -d -m 0755 /usr/local/sbin /usr/local/share/travel-mode'

echo "==> Copying interface configs to /usr/local/share/travel-mode/"
scp -q interfaces.home interfaces.travel "$PVE_HOST:/usr/local/share/travel-mode/"

echo "==> Copying executables to /usr/local/sbin/"
scp -q travel-mode-on travel-mode-off "$PVE_HOST:/usr/local/sbin/"
ssh "$PVE_HOST" 'chmod 0755 /usr/local/sbin/travel-mode-on /usr/local/sbin/travel-mode-off'

echo "==> Done."
echo
echo "Run on PVE host:"
echo "  ssh $PVE_HOST travel-mode-on    # before unplugging"
echo "  ssh $PVE_HOST travel-mode-off   # after returning home"
