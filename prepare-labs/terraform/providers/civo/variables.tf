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
