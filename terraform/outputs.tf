output "test_vm_id" {
  description = "PVE VMID assigned to the test VM"
  value       = proxmox_virtual_environment_vm.test.vm_id
}

output "test_vm_name" {
  description = "Display name / cloud-init hostname"
  value       = proxmox_virtual_environment_vm.test.name
}

output "test_vm_ipv4_addresses" {
  description = "All IPv4 addresses reported by the QEMU guest agent (list per NIC)"
  value       = proxmox_virtual_environment_vm.test.ipv4_addresses
}
