variable "node_sizes" {
  type = map(any)
  default = {
    S = "t3.small"
    M = "t3.medium"
    L = "t3.large"
  }
}

variable "location" {
  type    = string
  default = "eu-north-1"
}
