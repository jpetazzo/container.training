provider "exoscale" {
  key    = regex("\n  key *= *\"([^\"]+)\"\n", file("~/.config/exoscale/exoscale.toml"))[0]
  secret = regex("\n  secret *= *\"([^\"]+)\"\n", file("~/.config/exoscale/exoscale.toml"))[0]
}

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
