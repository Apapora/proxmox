# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Homelab infrastructure-as-code repo. Manages a Proxmox VE 9 host with Terraform, Ansible, and related tooling. Primary purpose: hands-on learning of DevOps/SRE practices (containers, Kubernetes, monitoring, GitOps).

## Hardware

- **Host**: Beelink SER10 MAX — AMD Ryzen AI 9 HX 470, 64GB (32GB×2) DDR5 5600 MT/s, 1TB internal SSD
- **Hypervisor**: Proxmox VE 9 on Debian 13 (trixie), kernel 6.17.2-1-pve
- **Dock (unused)**: Beelink Mate SE 80Gbps — idle until SSDs added (deferred; learn first, expand when 1TB hits limit)

## Network

- Host IP: `10.0.0.19/24`, gateway `10.0.0.1`, **static** (configured at install)
- Hostname: `pve` (FQDN `pve.battlestarfoo`)
- Search domain: `battlestarfoo`
- Single bridge `vmbr0` over `nic0`; second NIC `nic1` is a stub (only one physical wired port on this hardware). Wifi `wlp194s0` exists but unused.
- Web UI: `https://10.0.0.19:8006`

## Goals

Primary: learn containers, Kubernetes, monitoring, GitOps, secrets management.
Secondary: media library (Plex/Jellyfin) + photo library (Immich).

## Planned Workloads

ArgoCD, Vault/OpenBao, Harbor, GitLab runners, Pi-hole, Grafana, Prometheus, Immich, Jellyfin/Plex, Portainer.

## Repo Layout

- `bootstrap/` — one-time host setup scripts (PVE itself)
  - `configure-apt-repos.sh` — switch from enterprise → no-subscription repos
  - `build-ubuntu-template.sh` — build VMID 9000 Ubuntu 24.04 cloud-init template
- `terraform/` — bpg/proxmox provider, VM/LXC provisioning (Phase 2)
- `ansible/` — playbooks, roles, dynamic inventory from Terraform output (Phase 3)
- `kubernetes/` — manifests, Helm values, ArgoCD apps (Phase 4+)
- `docs/decisions/` — ADRs (Architecture Decision Records). Read these to understand why choices were made.
- `.envrc` / `.envrc.example` — direnv-managed local secrets (gitignored / committed template)

## Build Phases

1. **Foundation** ← in progress — git scaffold, SSH hardening, PVE API token, storage layout, cloud-init template
2. **Terraform VM provisioning** — bpg/proxmox provider, modules for VM + LXC
3. **Ansible base config** — common role, container runtime, k8s prereqs
4. **K8s core** — k3s (recommended for this hardware) + CNI, MetalLB, ingress, cert-manager, storage class
5. **Platform tools** — ArgoCD first, then Vault, Harbor, Prometheus/Grafana, GitLab runners (all GitOps from here)
6. **User workloads** — Pi-hole (LXC), Plex/Jellyfin (LXC w/ AMD iGPU VA-API), Immich (k8s), Portainer

## Phase 1 status — Foundation ✓

All foundation tasks complete. See ADRs 0001-0007.

## Phase 2 status — Terraform VM provisioning

Walking-skeleton complete:

- OpenTofu CLI (chose over Terraform, see ADR 0007). Use `tofu` everywhere; `.tf` syntax unchanged.
- `terraform/providers.tf`, `variables.tf`, `main.tf`, `outputs.tf` — clone template 9000, cloud-init injects SSH key, QGA reports IP back, SSH from workstation lands as `ubuntu@<vm>`.
- `terraform/.terraform.lock.hcl` pins `bpg/proxmox v0.106.0`.
- Throwaway VM verified end-to-end then destroyed.

Two lessons baked in (apply to all future VM resources):

1. `TerraformProv` role needs `VM.GuestAgent.Audit` + `VM.GuestAgent.Unrestricted` on top of ADR 0003's original list. Without them, `ipv4_addresses` output stays empty (403 from agent endpoint). Already added on the host.
2. `initialization { upgrade = false }` — bpg defaults to `true` (= apt dist-upgrade on first boot). Slow, flaky, can abort cloud-init before ssh.socket starts. Always set `false`; Ansible owns package state from Phase 3 on.

Canonical `TerraformProv` privilege set (alphabetized):

```
Datastore.Allocate, Datastore.AllocateSpace, Datastore.AllocateTemplate,
Datastore.Audit, Mapping.Audit, Mapping.Modify, Mapping.Use, Pool.Allocate,
Pool.Audit, SDN.Use, Sys.Audit, Sys.Console, Sys.Modify, Sys.PowerMgmt,
VM.Allocate, VM.Audit, VM.Clone, VM.Config.CDROM, VM.Config.CPU,
VM.Config.Cloudinit, VM.Config.Disk, VM.Config.HWType, VM.Config.Memory,
VM.Config.Network, VM.Config.Options, VM.Console, VM.GuestAgent.Audit,
VM.GuestAgent.Unrestricted, VM.Migrate, VM.PowerMgmt, VM.Snapshot,
VM.Snapshot.Rollback
```

Next: design `terraform/modules/vm/` (reusable module), then provision the 3 k3s node VMs (1 server + 2 agents).

### Phase 2 — VM module + k3s VMs ✓

- `terraform/modules/vm/` — reusable VM module. Inputs: name, cpus, memory_mb, disk_size_gb, ip_address (CIDR or null=DHCP), gateway, ssh_public_keys, tags, etc. Outputs: vm_id, name, ipv4_address (flattened primary), ipv4_addresses_raw, mac_addresses.
- Root `terraform/main.tf` uses `for_each` over a `local.k3s_nodes` map → calls module 3×.
- Static IPs in 10.0.0.150-152 (above any default DHCP pool).
- Live VMs: `k3s-server-1` (.150), `k3s-agent-1` (.151), `k3s-agent-2` (.152). 4 vCPU, 8GB RAM, 40GB disk each. Cloud-init grows root fs to disk size.

Module gotcha: child modules using a non-default provider need their own `required_providers` block (`modules/vm/versions.tf`), else OpenTofu looks up `hashicorp/<name>` and fails.

### Phase 2 — Pi-hole + Media LXCs ✓

Architecture locked: k3s on the 3 VMs for app workloads + LXCs for foundational network services that must stay up independent of the cluster. No separate Docker VM.

- `bootstrap/download-lxc-template.sh` — idempotent puller for Debian 12 LXC template into `local` storage. Resolved version: `debian-12-standard_12.12-1_amd64.tar.zst`.
- `terraform/modules/lxc/` — reusable LXC module (`proxmox_virtual_environment_container`). Inputs mirror `modules/vm/` where they overlap.
- Live LXCs: `pihole` (.160, VMID 103, unprivileged) + `media` (.161, VMID 104, unprivileged).

**Hard PVE constraints on API tokens** (`terraform@pve`) — not bypassable via role privileges, enforced by hardcoded uid check:

1. **Privileged LXCs**: cannot create. Token can only create unprivileged.
2. **Feature flags**: only `nesting` allowed. `keyctl`, `fuse`, `mount`, etc. all require `root@pam`.
3. **Device passthrough**: requires `root@pam`. Cannot configure `/dev/dri` etc. via token.

Consequence: media LXC's iGPU passthrough for Jellyfin must happen out-of-band in a Phase 3 bootstrap step that SSHes to PVE as root and runs `pct set` directly (or edits `/etc/pve/lxc/<vmid>.conf`). Module is intentionally narrow.

Other LXC notes:
- Debian 12 LXC needs `features.nesting = true` because systemd 252 uses cgroup-v2 features blocked by default.
- LXCs use **root** user (not ubuntu) for SSH — `ssh root@10.0.0.160`.
- LXC's `ipv4_address` output trusts the configured static CIDR (no QGA inside LXC).

Next: Phase 3 — Ansible base config (common role, k3s prereqs) + Phase 4 (k3s install).

## Conventions

- **k8s distro**: k3s (lightweight, single-binary; fits this hardware better than kubeadm).
- **Terraform provider**: `bpg/proxmox` (not telmate — bpg is actively maintained, better feature parity).
- **Secrets**: never commit raw secrets. Plan = direnv for local, sops+age before any commit, Vault once deployed.
- **Naming**: PVE NICs are `nicN` (Proxmox 9 stable naming, not `enp*`).

## Quick Reference

```bash
ssh pve                                      # connect to hypervisor
curl -sk -H "Authorization: PVEAPIToken=terraform@pve!provisioner=$SECRET" \
  https://10.0.0.19:8006/api2/json/version    # smoke-test API token
```
