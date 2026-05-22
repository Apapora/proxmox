# terraform/

Declarative provisioning of VMs/LXCs on the Proxmox host via the
`bpg/proxmox` provider. Run with **OpenTofu** (`tofu` CLI) — see ADR 0007.

## Current state — walking skeleton

Single test VM resource cloning template 9000. Used to verify the
end-to-end pipeline (provider auth, API + SSH paths, cloud-init, QGA, SSH
back). Will be refactored into `modules/vm/` and called once per k3s node.

## Files

| File | Purpose |
|---|---|
| `providers.tf` | bpg/proxmox version pin + SSH sub-config |
| `variables.tf` | inputs (node, template id, vm name, ssh pubkey) |
| `main.tf` | the VM resource — clone, cloud-init, agent |
| `outputs.tf` | vm_id, name, ipv4_addresses |
| `.terraform.lock.hcl` | provider version + checksums (commit this) |

## Commands

```bash
tofu init           # first run / after version bumps
tofu plan           # diff
tofu apply          # execute
tofu destroy        # tear down

# Force-recreate one resource (e.g. to re-trigger cloud-init):
tofu apply -replace=proxmox_virtual_environment_vm.test
```

## Env vars

All come from project root `.envrc` via direnv:

- `PROXMOX_VE_ENDPOINT`, `PROXMOX_VE_API_TOKEN`, `PROXMOX_VE_INSECURE`
- `PROXMOX_VE_SSH_USERNAME`, `PROXMOX_VE_SSH_AGENT`
- `TF_VAR_ssh_public_key` (auto-binds to `var.ssh_public_key`)

## Gotchas baked in

- `initialization { upgrade = false }` — bpg defaults to `true` (= apt
  dist-upgrade on first boot). Fragile, slow, can abort cloud-init.
- `bios = "ovmf"` + `machine = "q35"` set explicitly to match template 9000.
  bpg's plan output otherwise shows misleading `seabios` default.
- `clone { full = false }` = linked clone (fast, depends on template stay).
