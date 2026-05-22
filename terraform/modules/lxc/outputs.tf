output "vm_id" {
  description = "PVE-assigned (or explicit) VMID"
  value       = proxmox_virtual_environment_container.this.vm_id
}

output "name" {
  description = "LXC name (hostname)"
  value       = proxmox_virtual_environment_container.this.initialization[0].hostname
}

output "ipv4_address" {
  description = "Primary non-loopback IPv4 (parsed from the configured CIDR, if static)"
  value = try(
    split("/", proxmox_virtual_environment_container.this.initialization[0].ip_config[0].ipv4[0].address)[0],
    null
  )
}
