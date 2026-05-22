resource "proxmox_virtual_environment_vm" "this" {
  name        = var.name
  node_name   = var.node_name
  vm_id       = var.vm_id
  description = var.description
  tags        = var.tags
  on_boot     = var.on_boot
  started     = var.started

  # Match template 9000 (OVMF + Q35) so plan doesn't drift toward seabios/i440fx.
  bios    = "ovmf"
  machine = "q35"

  clone {
    vm_id = var.template_vm_id
    full  = false
  }

  agent {
    enabled = true
  }

  cpu {
    cores = var.cpus
    type  = var.cpu_type
  }

  memory {
    dedicated = var.memory_mb
  }

  # Resize boot disk on clone. cloud-init's growpart expands the filesystem
  # on first boot.
  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = var.disk_size_gb
    discard      = "on"
    ssd          = true
  }

  network_device {
    bridge = var.bridge
    model  = "virtio"
  }

  initialization {
    datastore_id = var.datastore_id
    interface    = "ide2"
    upgrade      = false

    user_account {
      username = var.username
      keys     = [for k in var.ssh_public_keys : trimspace(k)]
    }

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
  }
}
