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

locals {
  debian_12_template = "local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
}

module "pihole" {
  source = "./modules/lxc"

  name             = "pihole"
  template_file_id = local.debian_12_template

  cpus         = 1
  memory_mb    = 512
  disk_size_gb = 4

  ip_address = "10.0.0.160/24"
  gateway    = "10.0.0.1"

  ssh_public_keys = [var.ssh_public_key]

  unprivileged = true
  features = {
    # Debian 12 ships systemd 252 — needs nesting for cgroupv2 features.
    nesting = true
  }

  tags        = ["pihole", "network", "lxc", "terraform"]
  description = "Pi-hole DNS + ad-blocking. Foundational network tier (outside k3s)."
}

module "media" {
  source = "./modules/lxc"

  name             = "media"
  template_file_id = local.debian_12_template

  cpus         = 4
  memory_mb    = 4096
  disk_size_gb = 50

  ip_address = "10.0.0.161/24"
  gateway    = "10.0.0.1"

  ssh_public_keys = [var.ssh_public_key]

  # API token can only create unprivileged + nesting. Privileged conversion +
  # /dev/dri device attachment happen in a Phase-3 bootstrap step that SSHes
  # to PVE as root and runs `pct set` directly.
  unprivileged = true
  features = {
    nesting = true
  }

  tags        = ["media", "jellyfin", "lxc", "terraform"]
  description = "Jellyfin LXC. Convert to privileged + attach /dev/dri post-create."
}

module "ollama" {
  source = "./modules/lxc"

  name             = "ollama"
  template_file_id = local.debian_12_template

  # CPU-only inference. iGPU passthrough deliberately skipped:
  cpus         = 6
  memory_mb    = 12288
  disk_size_gb = 30

  ip_address = "10.0.0.162/24"
  gateway    = "10.0.0.1"

  ssh_public_keys = [var.ssh_public_key]

  unprivileged = true
  features = {
    nesting = true
  }

  tags        = ["ollama", "llm", "ai", "lxc", "terraform"]
  description = "Ollama LLM server (CPU-only)."
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
