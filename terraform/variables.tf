variable "proxmox_node" {
  description = "Name of the Proxmox node to deploy on"
  type        = string
  default     = "pve"
}

variable "template_vm_id" {
  description = "VMID of the source cloud-init template (built by bootstrap/build-ubuntu-template.sh)"
  type        = number
  default     = 9000

  validation {
    condition     = var.template_vm_id >= 100 && var.template_vm_id <= 999999999
    error_message = "PVE VMIDs must be between 100 and 999999999."
  }
}

variable "vm_name" {
  description = "Display name + cloud-init hostname for the VM"
  type        = string
  default     = "test-vm-01"
}

variable "ssh_public_key" {
  description = "SSH public key to inject via cloud-init for the default user"
  type        = string
  # No default — must be supplied via TF_VAR_ssh_public_key (set in .envrc)
}
