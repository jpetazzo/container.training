variable "node_sizes" {
  type = map(any)
  default = {
    S = "d2-4"
    M = "d2-4"
    L = "d2-8"
  }
}

variable "location" {
  type    = string
  default = "BHS5"
}
