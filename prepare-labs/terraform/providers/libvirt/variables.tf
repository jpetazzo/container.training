# vCPUs and RAM (in MiB) are encoded as "vcpus ram" to keep the same
# pattern used by other providers (e.g. proxmox) in this project.
variable "node_sizes" {
  type = map(any)
  default = {
    XS = "1 512"
    S  = "1 2048"
    M  = "2 4096"
    L  = "4 8192"
  }
}

variable "location" {
  type    = string
  default = ""
  # TODO: make the location depending on libvirt_uri
  description = "Unused for libvirt (local hypervisor). Kept for interface consistency."
}

# variables.tf
variable "base_network" {
  description = "First network(ex: 192.168.200.0/24, 10.0.5.0/24, 172.16.30.0/24)"
  type        = string
  default     = "192.168.101.0/24"

  validation {
    condition     = can(cidrnetmask(var.base_network))
    error_message = "The network must be a valid CIDR (ex: 192.168.200.0/24)."
  }
}
