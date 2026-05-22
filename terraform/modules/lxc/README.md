# modules/lxc/

Reusable module that creates a Proxmox LXC container from a downloaded OS
template. Mirrors `modules/vm/` shape so the caller ergonomics are
consistent.

## Usage

```hcl
module "pihole" {
  source = "./modules/lxc"

  name             = "pihole"
  template_file_id = "local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
  cpus             = 1
  memory_mb        = 512
  disk_size_gb     = 4
  ip_address       = "10.0.0.160/24"
  gateway          = "10.0.0.1"
  ssh_public_keys  = [var.ssh_public_key]
  tags             = ["pihole", "network", "lxc"]
}
```

## LXC vs VM module — key differences

| | VM module | LXC module |
|---|---|---|
| Resource | `proxmox_virtual_environment_vm` | `proxmox_virtual_environment_container` |
| OS source | clone of cloud-init template VM | `operating_system { template_file_id }` |
| Cloud-init drive | yes (ide2 disk) | none — init fields go directly in `initialization` |
| Default user | `ubuntu` | none — root only |
| Privilege | always full VM | `unprivileged` defaults true; set false for device passthrough |
| Device passthrough | PCIe (complex) | `device_passthrough` block (simple bind-mount) |

## Inputs

See `variables.tf`. Required: `name`, `template_file_id`, `ssh_public_keys`.

### Privileged + device passthrough

For iGPU passthrough (Jellyfin, etc.):

```hcl
unprivileged = false
device_passthrough = [
  { path = "/dev/dri/card0" },
  { path = "/dev/dri/renderD128" },
]
```

`unprivileged = false` is needed because device passthrough with idmap on
unprivileged LXCs is non-trivial. Privileged + bind-mount is the pragmatic
homelab path.

## Outputs

- `vm_id` — chain into other resources
- `name` — hostname
- `ipv4_address` — parsed from the static CIDR. Note: LXC doesn't run the
  QEMU guest agent, so we can't query the live IP; we trust the configured
  static value.
