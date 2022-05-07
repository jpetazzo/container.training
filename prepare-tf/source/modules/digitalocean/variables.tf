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
    "S" = "s-1vcpu-2gb"
    "M" = "s-2vcpu-4gb"
    "L" = "s-4vcpu-8gb"
  }
}

locals {
  node_type = var.node_types[var.node_size]
}

# To view supported regions, run:
# doctl compute region list
variable "location" {
  type    = string
  default = null
}

# To view supported versions, run:
# doctl kubernetes options versions -o json | jq -r .[].slug
variable "k8s_version" {
  type    = string
  default = "1.22.8-do.1"
}
