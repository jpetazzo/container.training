provider "civo" {
  token = local.civo_apikey
}

locals {
  civo_config  = jsondecode(file("~/.civo.json"))
  civo_current = local.civo_config.meta.current_apikey
  civo_apikey  = local.civo_config.apikeys[local.civo_current]
}

variable "node_sizes" {
  type = map(any)
  default = {
    S = "g4s.kube.small"
    M = "g4s.kube.medium"
    L = "g4s.kube.large"
  }
}

variable "location" {
  type    = string
  default = "lon1"
}
