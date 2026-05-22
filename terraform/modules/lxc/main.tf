resource "proxmox_virtual_environment_container" "this" {
  node_name    = var.node_name
  vm_id        = var.vm_id
  description  = var.description
  tags         = var.tags
  unprivileged = var.unprivileged
  start_on_boot = var.on_boot
  started      = var.started

  operating_system {
    template_file_id = var.template_file_id
    type             = "debian"
  }

  cpu {
    cores = var.cpus
  }

  memory {
    dedicated = var.memory_mb
    swap      = var.swap_mb
  }

  disk {
    datastore_id = var.datastore_id
    size         = var.disk_size_gb
  }

  network_interface {
    name   = "eth0"
    bridge = var.bridge
  }

  initialization {
    hostname = var.name

    ip_config {
      ipv4 {
        address = var.ip_address == null ? "dhcp" : var.ip_address
        gateway = var.gateway
      }
    }

    dns {
      domain  = var.dns_domain
      servers = var.dns_servers
    }

    user_account {
      keys = [for k in var.ssh_public_keys : trimspace(k)]
    }
  }

  # PVE policy: API tokens may only set `nesting`. keyctl/fuse/mount/etc.
  # require root@pam — not exposed here. Same with privileged containers and
  # device_passthrough — those happen out-of-band post-create.
  features {
    nesting = var.features.nesting
  }
}
