# modules/vm/

Reusable module that clones a PVE cloud-init template into a configured VM.

## Usage

```hcl
module "k3s_server_1" {
  source = "./modules/vm"

  name            = "k3s-server-1"
  cpus            = 4
  memory_mb       = 8192
  disk_size_gb    = 40
  ip_address      = "10.0.0.30/24"
  gateway         = "10.0.0.1"
  ssh_public_keys = [var.ssh_public_key]
  tags            = ["k3s", "server"]
}
```

Or with `for_each` over a map for many VMs.

## Inputs

See `variables.tf` for the full list with descriptions.

Required: `name`, `ssh_public_keys`. Everything else has sensible defaults.

If you set `ip_address`, you must also set `gateway` (and vice versa). Validation
enforces this.

## Outputs

| Output | Use |
|---|---|
| `vm_id` | Chain into other resources (e.g., HA group membership) |
| `name` | Echo |
| `ipv4_address` | Flattened primary IP — feed into Ansible inventory |
| `ipv4_addresses_raw` | Full list-of-lists from QGA, for debugging |
| `mac_addresses` | Reserve in DHCP, build DNS records |

## Notes

- Linked clone (`full = false`) — fast, depends on template staying intact.
- `bios = "ovmf"` and `machine = "q35"` set explicitly to match template 9000.
- `initialization.upgrade = false` — see CLAUDE.md for rationale. Package
  management belongs to Ansible.
- Disk resize works because Ubuntu cloud images run `growpart` + `resize2fs`
  via cloud-init on first boot.
- Network NIC is virtio on `vmbr0` by default. Bridge is configurable for
  future VLAN trunking.
