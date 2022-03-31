variable "cluster_name" {
  type    = string
  default = "deployed-with-terraform"
}

variable "common_tags" {
  type    = list(string)
  default = []
}

variable "node_size" {
  type    = string
  default = "M"
}

variable "min_nodes_per_pool" {
  type    = number
  default = 2
}

variable "max_nodes_per_pool" {
  type    = number
  default = 5
}

# FIXME
variable "enable_arm_pool" {
  type    = bool
  default = false
}

variable "node_types" {
  type = map(string)
  default = {
    "S" = "g6-standard-1"
    "M" = "g6-standard-2"
    "L" = "g6-standard-4"
  }
}

locals {
  node_type = var.node_types[var.node_size]
}

# To view supported regions, run:
# linode-cli regions list
variable "location" {
  type    = string
  default = null
}

# To view supported versions, run:
# linode-cli lke versions-list --json | jq -r .[].id
variable "k8s_version" {
  type    = string
  default = "1.22"
}
