resource "proxmox_virtual_environment_vm" "test" {
  name        = var.vm_name
  node_name   = var.proxmox_node
  description = "Walking skeleton VM, managed by Terraform"
  tags        = ["terraform", "test", "throwaway"]

  # Match template 9000 — it uses OVMF/UEFI on a Q35 chipset.
  bios    = "ovmf"
  machine = "q35"

  clone {
    vm_id = var.template_vm_id
    full  = false
  }

  initialization {
    datastore_id = "local-lvm"
    interface    = "ide2"

    # Skip apt dist-upgrade on first boot — slow, flaky, and we pin
    # versions via Ansible later. Real nodes use immutable bases.
    upgrade = false

    user_account {
      username = "ubuntu"
      keys     = [trimspace(var.ssh_public_key)]
    }

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    dns {
      domain  = "battlestarfoo"
      servers = ["10.0.0.1"]
    }
  }

  agent {
    enabled = true
  }
}
