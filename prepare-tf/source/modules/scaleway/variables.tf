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
    "S" = "DEV1-S"
    "M" = "DEV1-M"
    "L" = "DEV1-L"
  }
}

locals {
  node_type = var.node_types[var.node_size]
}

variable "cni" {
  type    = string
  default = "cilium"
}

variable "location" {
  type    = string
  default = null
}

# To view supported versions, run:
# scw k8s version list -o json | jq -r .[].name
variable "k8s_version" {
  type    = string
  default = "1.22.2"
}
