variable "how_many_clusters" {
  type    = number
  default = 1
}

variable "node_size" {
  type    = string
  default = "M"
  # Can be S, M, L.
  # We map these values to different specific instance types for each provider,
  # but the idea is that they shoudl correspond to the following sizes:
  # S = 2 GB RAM
  # M = 4 GB RAM
  # L = 8 GB RAM
}

variable "min_nodes_per_pool" {
  type    = number
  default = 1
}

variable "max_nodes_per_pool" {
  type    = number
  default = 0
}

variable "enable_arm_pool" {
  type    = bool
  default = false
}

variable "location" {
  type    = string
  default = null
}

# TODO: perhaps handle if it's space-separated instead of newline?
locals {
  locations = var.location == null ? [null] : split("\n", var.location)
}
