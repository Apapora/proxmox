#!/usr/bin/env bash
# Build a Proxmox VM template from the Ubuntu 24.04 cloud image.
#
# Run this ON the Proxmox host (as root), not on your workstation:
#   scp bootstrap/build-ubuntu-template.sh pve:/root/
#   ssh pve "bash /root/build-ubuntu-template.sh"
#
# Idempotent: exits if VM ${VMID} already exists. To rebuild, destroy
# the template first:  qm destroy ${VMID}

set -euo pipefail

# --------------------------------------------------------------------
# Tunables
# --------------------------------------------------------------------
UBUNTU_CODENAME="noble"            # 24.04 LTS
UBUNTU_VERSION="24.04"
IMG_NAME="${UBUNTU_CODENAME}-server-cloudimg-amd64.img"
IMG_URL="https://cloud-images.ubuntu.com/${UBUNTU_CODENAME}/current/${IMG_NAME}"
SUMS_URL="https://cloud-images.ubuntu.com/${UBUNTU_CODENAME}/current/SHA256SUMS"

VMID="${VMID:-9000}"
VMNAME="ubuntu-${UBUNTU_VERSION//./}-cloud"   # ubuntu-2404-cloud
STORAGE="${STORAGE:-local-lvm}"               # where VM disks live
SNIPPETS_STORAGE="${SNIPPETS_STORAGE:-local}" # where snippets live
BRIDGE="${BRIDGE:-vmbr0}"
CORES="${CORES:-2}"
MEMORY="${MEMORY:-2048}"                      # MiB
CACHE_DIR="/var/lib/vz/template/iso"

# --------------------------------------------------------------------
# Pre-flight
# --------------------------------------------------------------------
[[ $EUID -eq 0 ]] || { echo "must run as root on the Proxmox host"; exit 1; }

if qm status "$VMID" &>/dev/null; then
  echo "VM $VMID already exists. Destroy it first if you want to rebuild:"
  echo "  qm destroy $VMID"
  exit 0
fi

echo "==> Ensuring libguestfs-tools is installed (for image customization)"
if ! command -v virt-customize &>/dev/null; then
  apt-get update -qq
  apt-get install -y -qq libguestfs-tools
fi

# --------------------------------------------------------------------
# Download + verify
# --------------------------------------------------------------------
mkdir -p "$CACHE_DIR"
cd "$CACHE_DIR"

echo "==> Downloading ${IMG_NAME} (if not cached)"
if [[ ! -f "$IMG_NAME" ]]; then
  curl -fsSL -O "$IMG_URL"
fi

echo "==> Downloading + verifying SHA256SUMS"
curl -fsSL -o SHA256SUMS "$SUMS_URL"
grep " \*${IMG_NAME}$" SHA256SUMS | sha256sum -c -

# --------------------------------------------------------------------
# Customize image — bake qemu-guest-agent in
# --------------------------------------------------------------------
WORK_IMG="${IMG_NAME%.img}-customized.img"
cp -f "$IMG_NAME" "$WORK_IMG"

echo "==> Injecting qemu-guest-agent into the image"
virt-customize -a "$WORK_IMG" \
  --install qemu-guest-agent \
  --run-command 'systemctl enable qemu-guest-agent'

# --------------------------------------------------------------------
# Create + configure the VM
# --------------------------------------------------------------------
echo "==> Creating VM $VMID ($VMNAME)"
qm create "$VMID" \
  --name "$VMNAME" \
  --cores "$CORES" \
  --memory "$MEMORY" \
  --cpu host \
  --net0 "virtio,bridge=$BRIDGE" \
  --scsihw virtio-scsi-single \
  --ostype l26 \
  --machine q35 \
  --bios ovmf \
  --agent enabled=1 \
  --serial0 socket \
  --vga serial0

echo "==> Adding EFI disk (needed for OVMF/UEFI boot)"
qm set "$VMID" --efidisk0 "${STORAGE}:0,format=raw,efitype=4m,pre-enrolled-keys=0"

echo "==> Importing cloud image as scsi0"
qm set "$VMID" --scsi0 "${STORAGE}:0,import-from=${CACHE_DIR}/${WORK_IMG},discard=on,ssd=1"

echo "==> Attaching cloud-init drive on ide2"
qm set "$VMID" --ide2 "${STORAGE}:cloudinit"

echo "==> Setting boot order to scsi0"
qm set "$VMID" --boot order=scsi0

echo "==> Configuring default cloud-init values (overridden per-clone by Terraform)"
qm set "$VMID" \
  --ciuser ubuntu \
  --ipconfig0 ip=dhcp \
  --searchdomain battlestarfoo \
  --nameserver 10.0.0.1

# --------------------------------------------------------------------
# Convert to template
# --------------------------------------------------------------------
echo "==> Converting VM $VMID to template"
qm template "$VMID"

echo
echo "==> Done. Template '$VMNAME' (VMID $VMID) ready."
echo "    Verify with: qm list | grep $VMID"
