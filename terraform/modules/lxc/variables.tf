variable "name" {
  description = "LXC name + hostname"
  type        = string
}

variable "node_name" {
  description = "PVE node to place the LXC on"
  type        = string
  default     = "pve"
}

variable "vm_id" {
  description = "Optional explicit VMID. null = auto-assign next free"
  type        = number
  default     = null
}

variable "template_file_id" {
  description = "Storage:vztmpl/<filename> of the LXC OS template"
  type        = string
}

variable "cpus" {
  description = "Number of CPU cores"
  type        = number
  default     = 1
}

variable "memory_mb" {
  description = "RAM in MiB"
  type        = number
  default     = 512
}

variable "swap_mb" {
  description = "Swap in MiB"
  type        = number
  default     = 512
}

variable "disk_size_gb" {
  description = "Root filesystem size in GB"
  type        = number
  default     = 8
}

variable "datastore_id" {
  description = "PVE storage for the rootfs"
  type        = string
  default     = "local-lvm"
}

variable "bridge" {
  description = "Linux bridge for the primary NIC"
  type        = string
  default     = "vmbr0"
}

variable "ip_address" {
  description = "Static IPv4 in CIDR form (e.g. '10.0.0.160/24'). null = DHCP."
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
  description = "DNS resolvers for the LXC"
  type        = list(string)
  default     = ["10.0.0.1"]
}

variable "dns_domain" {
  description = "DNS search domain"
  type        = string
  default     = "battlestarfoo"
}

variable "ssh_public_keys" {
  description = "SSH public keys installed for root (LXCs are minimal — no default user)"
  type        = list(string)
}

variable "unprivileged" {
  description = "Run LXC unprivileged (uid namespaced). Set false for device passthrough."
  type        = bool
  default     = true
}

variable "features" {
  description = "LXC feature flags"
  type = object({
    nesting = optional(bool, false)
    keyctl  = optional(bool, false)
    fuse    = optional(bool, false)
  })
  default = {}
}

variable "device_passthrough" {
  description = "Host device paths to pass through (e.g. /dev/dri/card0 for iGPU)"
  type = list(object({
    path = string
    mode = optional(string, "0660")
    uid  = optional(number, 0)
    gid  = optional(number, 0)
  }))
  default = []
}

variable "tags" {
  description = "PVE tags"
  type        = list(string)
  default     = []
}

variable "description" {
  description = "Free-text description shown in PVE UI"
  type        = string
  default     = ""
}

variable "on_boot" {
  description = "Auto-start at host boot"
  type        = bool
  default     = true
}

variable "started" {
  description = "Power on after creation"
  type        = bool
  default     = true
}
