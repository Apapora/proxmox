# 5. Use the bpg/proxmox Terraform provider

Date: 2026-05-21
Status: Accepted

## Context

Two main Terraform providers for Proxmox exist:

- `Telmate/proxmox` — older, was the default for years. Maintenance has been
  spotty. Known issues with cloud-init, snippet uploads, and feature parity
  with PVE 8+.
- `bpg/proxmox` — actively maintained, broader resource coverage, better
  cloud-init story (uses SSH to upload snippets), supports PVE 8+ features.

## Decision

Use `bpg/proxmox`. Specifically `bpg/proxmox` from the Terraform Registry.

## Consequences

- Provider needs both API token (for most resources) and SSH access (for
  snippet uploads). Already configured via `.envrc`: `PROXMOX_VE_API_TOKEN`,
  `PROXMOX_VE_SSH_USERNAME=root`, `PROXMOX_VE_SSH_AGENT=true`.
- Provider docs are excellent — defer to upstream for resource-specific
  questions: <https://registry.terraform.io/providers/bpg/proxmox/latest/docs>.
- If something is missing in bpg, fallback is manual `qm`/`pct` invocation
  via Ansible or `bootstrap/` scripts — do not switch back to Telmate.
