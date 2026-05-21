# 6. LVM-thin on internal SSD now, ZFS on dock SSDs later

Date: 2026-05-21
Status: Accepted

## Context

The PVE installer set up the default layout on the single 1TB NVMe:

- VG `pve` with thick `root` (96G), thick `swap` (8G), thin pool `data`
  (794G) backing the `local-lvm` storage entry.

The Beelink Mate SE 80Gbps dock is owned but unused — no SSDs in it yet.

Two reasonable choices for the internal disk:

1. Keep LVM-thin (default).
2. Reinstall PVE on ZFS to get snapshots, compression, integrity, send/recv.

Single-disk ZFS gives no redundancy (mirror needs two disks). Reinstall would
require redoing SSH hardening + API token (~30 min of work, all already
documented in memory).

## Decision

- Keep the default LVM-thin layout on the internal NVMe.
- When dock + 2× SSDs land, build a ZFS mirror on the dock as a second
  storage tier — bulk data (media, photos, backups, non-latency-sensitive
  PVs).

LVM stays the foundation for the hypervisor and VM/LXC disks. ZFS becomes
the bulk tier when hardware exists for it.

## Consequences

- LVM is more universal across Linux distros — transferable skill. ZFS is
  more powerful but adds RAM usage and operational complexity.
- Need to add `snippets` content type to `local` (done) so Terraform can
  upload cloud-init configs.
- Workload placement when dock is live: etcd/databases on internal LVM-thin,
  media/photos/backups on ZFS mirror.
- VG `pve` has ~16GB unallocated — left as headroom, not pre-carved.
