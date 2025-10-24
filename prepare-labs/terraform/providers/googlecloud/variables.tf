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
  default = "europe-north1-a"
}

locals {
  location = (var.location != "" && var.location != null) ? var.location : "europe-north1-a"
}