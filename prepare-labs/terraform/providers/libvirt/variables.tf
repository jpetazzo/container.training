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
