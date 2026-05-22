variable "name" {
  description = "VM name + cloud-init hostname"
  type        = string
}

variable "node_name" {
  description = "PVE node to place the VM on"
  type        = string
  default     = "pve"
}

variable "template_vm_id" {
  description = "VMID of the source cloud-init template"
  type        = number
  default     = 9000
}

variable "vm_id" {
  description = "Optional explicit VMID. null = auto-assign next free"
  type        = number
  default     = null
}

variable "cpus" {
  description = "Number of vCPUs"
  type        = number
  default     = 2
}

variable "cpu_type" {
  description = "QEMU CPU type — 'host' = passes physical flags (best perf)"
  type        = string
  default     = "host"
}

variable "memory_mb" {
  description = "RAM in MiB"
  type        = number
  default     = 2048
}

variable "disk_size_gb" {
  description = "Boot disk size in GB. Cloud image auto-expands via growpart on first boot."
  type        = number
  default     = 20
}

variable "datastore_id" {
  description = "PVE storage entry for VM disks + cloud-init drive"
  type        = string
  default     = "local-lvm"
}

variable "bridge" {
  description = "Linux bridge to attach the primary NIC to"
  type        = string
  default     = "vmbr0"
}

variable "ip_address" {
  description = "Static IPv4 in CIDR form (e.g. '10.0.0.30/24'). null = DHCP."
  type        = string
  default     = null
}

variable "gateway" {
  description = "IPv4 gateway. Required when ip_address is set."
  type        = string
  default     = null

  validation {
    condition     = (var.gateway == null) == (var.ip_address == null)
    error_message = "gateway must be set if and only if ip_address is set."
  }
}

variable "dns_servers" {
  description = "DNS resolvers for the VM"
  type        = list(string)
  default     = ["10.0.0.1"]
}

variable "dns_domain" {
  description = "DNS search domain"
  type        = string
  default     = "battlestarfoo"
}

variable "ssh_public_keys" {
  description = "SSH public keys to install for the default user via cloud-init"
  type        = list(string)
}

variable "username" {
  description = "Default user created by cloud-init"
  type        = string
  default     = "ubuntu"
}

variable "tags" {
  description = "PVE tags for filtering / grouping"
  type        = list(string)
  default     = []
}

variable "description" {
  description = "Free-text description shown in PVE UI"
  type        = string
  default     = ""
}

variable "on_boot" {
  description = "Auto-start this VM when the PVE host boots"
  type        = bool
  default     = true
}

variable "started" {
  description = "Power on the VM immediately after creation"
  type        = bool
  default     = true
}
