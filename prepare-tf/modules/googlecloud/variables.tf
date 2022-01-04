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
    "S" = "e2-small"
    "M" = "e2-medium"
    "L" = "e2-standard-2"
  }
}

locals {
  node_type = var.node_types[var.node_size]
}

# See supported versions with:
# gcloud container get-server-config --region=europe-north1 '--format=flattened(channels)'
# But it's also possible to just specify e.g. "1.20" and it figures it out.
variable "k8s_version" {
  type    = string
  default = "1.21"
}
