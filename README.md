# Homelab — Proxmox VE 9

Infrastructure-as-code for a single-host Proxmox VE 9 homelab. Built as a
hands-on DevOps/SRE learning environment.

Hardware: Beelink SER10 MAX, Ryzen AI 9 HX 470, 64GB DDR5, 1TB NVMe.

## Goals

- Learn containers, Kubernetes, GitOps, monitoring, secrets management
- Serve as personal media library (Plex/Jellyfin) + photo library (Immich)

## Architecture

```
Workstation (WSL2)                        PVE host (10.0.0.19)
─────────────────                         ─────────────────────
terraform CLI      ── HTTPS ──►           pveproxy (API)
ansible CLI        ── SSH   ──►           sshd
kubectl            ── HTTPS ──►           VMs running k3s

                                          ┌─────────────────────┐
                                          │ Template: VMID 9000 │
                                          │ ubuntu-2404-cloud   │
                                          └─────────────────────┘
                                                    │ clone
                                                    ▼
                                          ┌─────────────────────┐
                                          │ VM: k3s-server-1    │
                                          │ VM: k3s-agent-1     │
                                          │ VM: k3s-agent-2     │
                                          └─────────────────────┘
```

## Repo layout

| Path | Purpose |
|---|---|
| `bootstrap/` | One-time scripts that prepare the PVE host itself |
| `terraform/` | Declarative VM/LXC provisioning via `bpg/proxmox` |
| `ansible/` | Post-provision config of VMs (k3s prereqs, packages, services) |
| `kubernetes/` | Manifests, Helm values, ArgoCD apps (Phase 4+) |
| `docs/decisions/` | Architecture Decision Records (ADRs) |
| `.envrc` | direnv-managed local secrets (gitignored) |
| `.envrc.example` | template — copy to `.envrc`, fill in |
| `CLAUDE.md` | Project context for AI assistance |

## Build phases

1. **Foundation** — git scaffold, SSH hardening, PVE API token, storage decision, cloud-init template ✓
2. **Terraform VM provisioning** — bpg/proxmox provider, VM module, k3s node VMs
3. **Ansible base config** — common role, container runtime, k3s prereqs
4. **k3s cluster** — install + core networking (CNI, ingress, MetalLB, storage class)
5. **Platform tools** — ArgoCD → Vault → Harbor → Prometheus/Grafana → GitLab runners
6. **User workloads** — Pi-hole, Plex/Jellyfin, Immich, Portainer

## Day-one setup (new workstation)

```bash
# clone the repo (when remote exists)
git clone <repo-url> proxmox && cd proxmox

# install direnv if not already
sudo apt install -y direnv
echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
exec bash

# create local secret file
cp .envrc.example .envrc
$EDITOR .envrc          # fill in real PVE token secret
direnv allow

# verify the API token works
curl -sk -H "Authorization: PVEAPIToken=${PROXMOX_VE_API_TOKEN}" \
  "${PROXMOX_VE_ENDPOINT}/api2/json/version"
```

## Bootstrap (new PVE host)

In order:

```bash
ssh pve "bash -s" < bootstrap/configure-apt-repos.sh
ssh pve "bash -s" < bootstrap/build-ubuntu-template.sh
```

Manual steps still required (one-time, via web UI):

- Create user `terraform@pve` + role `TerraformProv` + API token `provisioner`
  (see `docs/decisions/0003-pve-api-token-and-role.md`)
- SSH hardening drop-in at `/etc/ssh/sshd_config.d/99-hardening.conf`
  (see `docs/decisions/0002-ssh-hardening.md`)

These will eventually be codified in Ansible.

## Conventions

- **k8s distro**: k3s (see `docs/decisions/0004-use-k3s.md`)
- **Terraform provider**: `bpg/proxmox` (see `docs/decisions/0005-bpg-proxmox-provider.md`)
- **Storage**: LVM-thin now, ZFS mirror on dock SSDs later (see `docs/decisions/0006-lvm-thin-vs-zfs.md`)
- **Secrets**: direnv for local now, sops+age before any commit touches secrets, Vault once deployed
- **Commits**: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`)

## Useful commands

```bash
ssh pve                                          # connect to hypervisor
ssh pve "qm list"                                # list VMs
ssh pve "pvesm status"                           # storage status
direnv reload                                    # re-source .envrc after edits
```
