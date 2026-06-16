output "pihole" {
  description = "Pi-hole LXC connection info"
  value = {
    vm_id        = module.pihole.vm_id
    name         = module.pihole.name
    ipv4_address = module.pihole.ipv4_address
  }
}

output "media" {
  description = "Media (Jellyfin) LXC connection info"
  value = {
    vm_id        = module.media.vm_id
    name         = module.media.name
    ipv4_address = module.media.ipv4_address
  }
}

output "ollama" {
  description = "Ollama LXC connection info"
  value = {
    vm_id        = module.ollama.vm_id
    name         = module.ollama.name
    ipv4_address = module.ollama.ipv4_address
  }
}

output "hermes" {
  description = "Hermes LXC connection info"
  value = {
    vm_id        = module.hermes.vm_id
    name         = module.hermes.name
    ipv4_address = module.hermes.ipv4_address
  }
}

output "k3s_nodes" {
  description = "Map of node name -> connection info, ready for Ansible inventory"
  value = {
    for k, m in module.k3s_nodes : k => {
      vm_id        = m.vm_id
      ipv4_address = m.ipv4_address
      mac          = try(m.mac_addresses[0], null)
    }
  }
}

output "k3s_server_ip" {
  description = "Convenience: IP of the k3s server node"
  value       = module.k3s_nodes["k3s-server-1"].ipv4_address
}

output "k3s_agent_ips" {
  description = "Convenience: IPs of the k3s agent nodes"
  value       = [for k, m in module.k3s_nodes : m.ipv4_address if startswith(k, "k3s-agent-")]
}
