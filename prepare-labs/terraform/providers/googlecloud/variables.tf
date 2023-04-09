variable "node_sizes" {
  type = map(string)
  default = {
    "S" = "e2-small"
    "M" = "e2-medium"
    "L" = "e2-standard-2"
  }
}

variable "location" {
  type    = string
  default = null
}
