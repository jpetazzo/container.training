variable "proxmox_endpoint" {
  type    = string
  default = "https://localhost:8006/"
}

variable "proxmox_username" {
  type    = string
  default = null
}

variable "proxmox_password" {
  type    = string
  default = null
}

variable "proxmox_storage" {
  type    = string
  default = "local"
}

variable "proxmox_template_node_name" {
  type    = string
  default = null
}

variable "proxmox_template_vm_id" {
  type    = number
  default = null
}

