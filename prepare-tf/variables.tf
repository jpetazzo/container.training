variable "how_many_clusters" {
  type    = number
  default = 2
}

variable "node_size" {
  type    = string
  default = "M"
  # Can be S, M, L.
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
  default = true
}
