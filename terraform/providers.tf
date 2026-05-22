terraform {
  required_version = ">= 1.9.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66"
    }
  }
}

provider "proxmox" {
  # Endpoint, API token, and insecure flag come from PROXMOX_VE_* env vars
  # loaded by direnv from the repo-root .envrc. Do not duplicate secrets here.

  ssh {
    agent    = true
    username = "root"
  }
}
