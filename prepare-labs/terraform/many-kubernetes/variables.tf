variable "tag" {
  type = string
}

variable "how_many_clusters" {
  type    = number
  default = 2
}

variable "min_nodes_per_cluster" {
  type    = number
  default = 2
}

variable "max_nodes_per_cluster" {
  type    = number
  default = 4
}

variable "node_size" {
  type    = string
  default = "M"
}

variable "location" {
  type    = string
  default = null
}

# TODO: perhaps handle if it's space-separated instead of newline?
locals {
  locations = var.location == null ? [null] : split("\n", var.location)
}
