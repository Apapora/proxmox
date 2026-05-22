output "vm_id" {
  description = "PVE-assigned (or explicit) VMID"
  value       = proxmox_virtual_environment_vm.this.vm_id
}

output "name" {
  description = "VM name as registered in PVE"
  value       = proxmox_virtual_environment_vm.this.name
}

# Flatten ipv4_addresses (list of lists, one per NIC) into the first
# non-loopback address. Convenient for chaining into Ansible inventory,
# DNS records, etc.
output "ipv4_address" {
  description = "Primary non-loopback IPv4 reported by QGA"
  value = try(
    [
      for addr in flatten(proxmox_virtual_environment_vm.this.ipv4_addresses) :
      addr if addr != "127.0.0.1" && !startswith(addr, "169.254.")
    ][0],
    null
  )
}

output "ipv4_addresses_raw" {
  description = "Full ipv4_addresses output (list per NIC) for debugging"
  value       = proxmox_virtual_environment_vm.this.ipv4_addresses
}

output "mac_addresses" {
  description = "MAC addresses of all NICs"
  value       = proxmox_virtual_environment_vm.this.mac_addresses
}
