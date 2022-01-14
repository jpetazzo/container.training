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

# To view supported locations, run:
# gcloud compute zones list
variable "location" {
  type    = string
  default = null
}

# To view supported versions, run:
# gcloud container get-server-config --region=europe-north1 '--format=flattened(channels)'
# But it's also possible to just specify e.g. "1.20" and it figures it out.
variable "k8s_version" {
  type    = string
  default = "1.21"
}

locals {
  location = var.location != null ? var.location : "europe-north1-a"
  region   = replace(local.location, "/-[a-z]$/", "")
  # Unfortunately, the following line doesn't work
  # (that attribute just returns an empty string)
  # so we have to hard-code the project name.
  #project = data.google_client_config._.project
  project = "prepare-tf"
}
