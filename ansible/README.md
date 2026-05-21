# ansible/

Post-provision configuration of VMs created by Terraform.

Empty until Phase 3 begins.

## Conventions (planned)

- `ansible.cfg` at this directory's root pins behaviors (inventory path, ssh
  args, host key checking).
- Dynamic inventory generated from Terraform outputs (option A) OR a static
  inventory file populated by Terraform `local_file` resources (option B).
  Will choose during Phase 3 design.
- Roles in `roles/`, playbooks in `playbooks/`.
- Vault-encrypted secrets via `ansible-vault`. Vault password file is
  gitignored — `.vault_pass`.
