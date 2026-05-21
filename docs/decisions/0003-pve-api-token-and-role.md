# 3. PVE API token and least-privilege role for Terraform

Date: 2026-05-20
Status: Accepted

## Context

Terraform needs to call the PVE API. Using `root@pam` would work but violates
least privilege: a leaked tfvars file or compromised workstation would yield
full hypervisor control. Tokens are PVE's machine-credential primitive — they
beat passwords on revocability, scoping, audit, and 2FA-compatibility.

## Decision

- Realm: `pve` (Proxmox VE auth server). Service accounts live here; humans
  live in `pam`.
- User: `terraform@pve`, no usable password (token-only).
- Role: custom `TerraformProv` with the privilege set required by the
  `bpg/proxmox` provider — see role contents in `reference_pve_host` memory
  and on the host.
- Token: `terraform@pve!provisioner`, privilege separation **disabled** (token
  inherits user privs — simpler than dual-ACL). No expiry for now.
- ACL: role bound at path `/` with propagate, datacenter-wide. Acceptable for
  a single-host lab; scope down if multi-tenant.

Secret stored locally in gitignored `.envrc` (direnv). Migration plan:
sops+age before any commit could touch a secret, then Vault once deployed.

## Consequences

- Terraform cannot use root credentials. Forces correct ACL coverage — if
  Terraform fails with 403, the role needs a privilege added, not "use root".
- Token can be rotated independently of any other credentials. Plan to rotate
  yearly as hygiene.
- Future automation (Ansible, ArgoCD-driven provisioning) should get their
  own tokens, not reuse `provisioner`. Naming pattern: `terraform@pve!<tool>`.
