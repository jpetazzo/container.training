# ------------------------------------------------------------------------------------------
#  Libvirt access
# ------------------------------------------------------------------------------------------
variable "libvirt_uri" {
  type        = string
  default     = "qemu:///system"
  description = "libvirt connection URI. Use qemu:///system for local, or qemu+ssh://user@host/system for remote."
}

# ------------------------------------------------------------------------------------------
# Domain image
# ------------------------------------------------------------------------------------------
variable "libvirt_base_image_url" {
  type        = string
  default     = "https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img"
  description = "URL or local path of the Ubuntu cloud image used as base disk for VMs."
}

# =======
#
#   TODO: make the next configuration dynamics depending on how many clusters are built.
#         - A different network must be created by each cluster
#         - The host firewall must be updated if necessary (use: /etc/libvirt/hooks/)
# =======

# ------------------------------------------------------------------------------------------
#  Storage configuration
# ------------------------------------------------------------------------------------------
variable "libvirt_volume_pool" {
  type        = string
  default     = "default"
  description = "Name of the libvirt storage pool where VM volumes will be created."
}

# ------------------------------------------------------------------------------------------
#  Network configuration
# ------------------------------------------------------------------------------------------

variable "libvirt_network_name" {
  type        = string
  default     = ""
  description = "Name of the libvirt network to attach VMs to. Leave empty to create a dedicated NAT network."
}

variable "libvirt_network_domain_name" {
  type        = string
  default     = "container.training"
  description = "Name of the libvirt network domain"
}


variable "libvirt_network_ips_address" {
  type        = string
  default     = "192.168.200.254"
  description = "Address of the created virtual network device. This is default route."
}

variable "libvirt_network_ips_prefix" {
  type        = number
  default     = 24
  description = "Prefix used to define network netmask."
}

variable "libvirt_network_ips_dhcp_range_start" {
  type        = string
  default     = "192.168.200.1"
  description = "First address in range of dhcp leases"
}

variable "libvirt_network_ips_dhcp_range_end" {
  type        = string
  default     = "192.168.200.100"
  description = "First address in range of dhcp leases"
}

