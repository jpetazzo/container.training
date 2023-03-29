variable "node_sizes" {
  type = map(any)
  default = {
    S = "DEV1-S"
    M = "DEV1-M"
    L = "DEV1-L"
  }
}

variable "location" {
  type    = string
  default = "fr-par-2"
}
