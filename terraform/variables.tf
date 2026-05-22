variable "ssh_public_key" {
  description = "SSH public key injected via cloud-init for all VMs. Supplied via TF_VAR_ssh_public_key in .envrc."
  type        = string
}
