#!/usr/bin/env bash
# Configure APT repos on a fresh Proxmox VE 9 install for homelab use.
#
# - Disables enterprise pve repo (requires paid subscription)
# - Disables enterprise ceph repo (we don't run ceph)
# - Adds the free pve-no-subscription repo
# - Runs apt update
#
# Run on the Proxmox host as root.

set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "must run as root on the Proxmox host"; exit 1; }

echo "==> Disabling enterprise PVE repo"
cat > /etc/apt/sources.list.d/pve-enterprise.sources <<'EOF'
# Disabled — homelab uses pve-no-subscription instead.
# To re-enable for a paid subscription, set Enabled: yes.
Types: deb
URIs: https://enterprise.proxmox.com/debian/pve
Suites: trixie
Components: pve-enterprise
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
Enabled: no
EOF

echo "==> Disabling enterprise Ceph repo (we don't run ceph)"
cat > /etc/apt/sources.list.d/ceph.sources <<'EOF'
# Disabled — no ceph workload in this homelab.
Types: deb
URIs: https://enterprise.proxmox.com/debian/ceph-squid
Suites: trixie
Components: enterprise
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
Enabled: no
EOF

echo "==> Adding pve-no-subscription repo"
cat > /etc/apt/sources.list.d/pve-no-subscription.sources <<'EOF'
# Free repo for non-production / homelab use.
# Slightly less QA'd than pve-enterprise. Acceptable for learning environments.
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF

echo "==> apt update"
apt-get update

echo "==> Done. Active sources:"
apt-cache policy 2>/dev/null | grep -E 'proxmox|debian.org' | head -20
