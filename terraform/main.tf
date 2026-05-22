locals {
  # k3s cluster topology. Static IPs in 10.0.0.150-152 — chosen high enough
  # to be above typical DHCP pool defaults. Adjust if router DHCP covers this.
  k3s_nodes = {
    "k3s-server-1" = {
      role         = "server"
      ip           = "10.0.0.150"
      cpus         = 4
      memory_mb    = 8192
      disk_size_gb = 40
    }
    "k3s-agent-1" = {
      role         = "agent"
      ip           = "10.0.0.151"
      cpus         = 4
      memory_mb    = 8192
      disk_size_gb = 40
    }
    "k3s-agent-2" = {
      role         = "agent"
      ip           = "10.0.0.152"
      cpus         = 4
      memory_mb    = 8192
      disk_size_gb = 40
    }
  }
}

module "k3s_nodes" {
  source   = "./modules/vm"
  for_each = local.k3s_nodes

  name         = each.key
  cpus         = each.value.cpus
  memory_mb    = each.value.memory_mb
  disk_size_gb = each.value.disk_size_gb

  ip_address = "${each.value.ip}/24"
  gateway    = "10.0.0.1"

  tags        = ["k3s", each.value.role, "terraform"]
  description = "k3s ${each.value.role} node, managed by Terraform"

  ssh_public_keys = [var.ssh_public_key]
}
