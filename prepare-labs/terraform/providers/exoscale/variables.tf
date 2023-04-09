variable "node_sizes" {
  type = map(any)
  default = {
    S = "standard.small"
    M = "standard.medium"
    L = "standard.large"
  }
}

variable "location" {
  type    = string
  default = "ch-gva-2"
}
