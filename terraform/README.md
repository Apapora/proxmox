# terraform/

Declarative provisioning of VMs/LXCs on the Proxmox host via the
`bpg/proxmox` provider.

Empty until Phase 2 begins.

## Conventions (planned)

- Provider config in `providers.tf`, version-pinned
- Root module assembles workloads from `modules/vm/` etc.
- State stays local during Phase 2 (single operator). Move to remote backend
  once collaboration or CI/CD requires it.
- Required env vars come from project root `.envrc` (loaded by direnv on
  `cd`):
  - `PROXMOX_VE_ENDPOINT`
  - `PROXMOX_VE_API_TOKEN`
  - `PROXMOX_VE_INSECURE`
  - `PROXMOX_VE_SSH_USERNAME`
  - `PROXMOX_VE_SSH_AGENT`
