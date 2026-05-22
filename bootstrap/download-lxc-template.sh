#!/usr/bin/env bash
# Download the Debian 12 standard LXC template into the PVE `local` storage.
#
# Run on the PVE host:
#   ssh pve "bash -s" < bootstrap/download-lxc-template.sh
#
# Idempotent: skips download if a matching template is already present.

set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "must run as root on the Proxmox host"; exit 1; }

STORAGE="${STORAGE:-local}"
TEMPLATE_GLOB="debian-12-standard_*_amd64.tar.zst"

echo "==> Refreshing pveam template index"
pveam update >/dev/null

echo "==> Checking for existing Debian 12 template in storage ${STORAGE}"
EXISTING="$(pveam list "$STORAGE" 2>/dev/null | awk -v s="$STORAGE" '$1 ~ "^" s ":vztmpl/debian-12-standard_" {print $1}' || true)"
if [[ -n "$EXISTING" ]]; then
  echo "    already present: $EXISTING"
  echo "$EXISTING"
  exit 0
fi

echo "==> Resolving latest Debian 12 standard template name"
TEMPLATE_NAME="$(pveam available --section system | awk '/debian-12-standard.*amd64\.tar\.zst$/ {print $2}' | sort -V | tail -1)"
if [[ -z "$TEMPLATE_NAME" ]]; then
  echo "ERROR: could not find debian-12-standard template in pveam available output"
  exit 1
fi
echo "    will download: $TEMPLATE_NAME"

echo "==> Downloading into ${STORAGE}"
pveam download "$STORAGE" "$TEMPLATE_NAME"

FINAL_ID="${STORAGE}:vztmpl/${TEMPLATE_NAME}"
echo
echo "==> Done. Template id for Terraform:"
echo "$FINAL_ID"
