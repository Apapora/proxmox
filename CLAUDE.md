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

## Phase 1 status — Foundation

All foundation tasks complete:

- Git scaffold + IaC-aware `.gitignore` (tfstate, vault pass, ssh keys, env, direnv)
- SSH hardened on PVE — see ADR 0002
- PVE API token + custom `TerraformProv` role — see ADR 0003
- direnv loading `.envrc` with PVE endpoint/token on `cd` into repo
- APT repos: enterprise disabled, `pve-no-subscription` active
- Storage layout: keep LVM-thin default, plan ZFS for dock SSDs later — see ADR 0006
- Cloud-init Ubuntu 24.04 template: VMID 9000, `ubuntu-2404-cloud`, QGA baked in
- Repo scaffold: `bootstrap/`, `terraform/`, `ansible/`, `kubernetes/`, `docs/decisions/`

Next: initial commit (task 7), then Phase 2 — write the first Terraform to clone the template into k3s node VMs.

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
