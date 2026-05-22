# 7. Use OpenTofu instead of Terraform

Date: 2026-05-21
Status: Accepted (supersedes implicit "Terraform" assumption in earlier ADRs)

## Context

HashiCorp relicensed Terraform from MPL 2.0 to BUSL 1.1 in August 2023,
making it source-available, not open source. The Linux Foundation accepted
a community fork, OpenTofu, in September 2023; it remains MPL 2.0. IBM
acquired HashiCorp in 2024; no license reversal followed.

Both tools speak identical HCL, share the same provider ecosystem
(including `bpg/proxmox`), and use the same state format.

## Decision

Use OpenTofu (`tofu` CLI) for all IaC in this repo.

- Install via the official OpenTofu installer (`get.opentofu.org`)
- All commands use `tofu` — `tofu init`, `tofu plan`, `tofu apply`, etc.
- File suffix stays `.tf` (keeps editor tooling and provider docs aligned)
- Provider name stays `bpg/proxmox` in `required_providers`

## Consequences

- Tutorials saying "terraform <cmd>" still apply — substitute `tofu`.
- OpenTofu-only features (state encryption, `removed` blocks) available
  if/when justified.
- Migration in either direction is trivial — state format compatible.
