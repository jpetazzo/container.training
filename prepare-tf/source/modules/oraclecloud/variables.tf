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

variable "enable_arm_pool" {
  type    = bool
  default = true
}

locals {
  arm_pool = {
    shape = "VM.Standard.A1.Flex"
  }
  x86_pool = {
    shape = "VM.Standard.E4.Flex"
  }
  pools = var.enable_arm_pool ? {
    "oke-arm" = local.arm_pool
    "oke-x86" = local.x86_pool
    } : {
    "oke-x86" = local.x86_pool
  }
}

output "pool" {
  value = local.pools
}

variable "node_types" {
  # FIXME put better typing here
  type = map(map(number))
  default = {
    "S" = {
      memory_in_gbs = 2
      ocpus         = 1
    }
    "M" = {
      memory_in_gbs = 4
      ocpus         = 1
    }
    "L" = {
      memory_in_gbs = 8
      ocpus         = 2
    }
  }
}

locals {
  node_type = var.node_types[var.node_size]
}

# To view supported regions, run:
# oci iam region list | jq .data[].name
variable "location" {
  type    = string
  default = null
}

# To view supported versions, run:
# oci ce cluster-options get --cluster-option-id all | jq -r '.data["kubernetes-versions"][]'
variable "k8s_version" {
  type    = string
  default = "v1.20.11"
}
