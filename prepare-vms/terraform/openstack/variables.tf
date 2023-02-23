variable "prefix" {
  type = string
}

variable "how_many_nodes" {
  type = number
}

variable "flavor" {
  type = string
}

variable "image" {
  type    = string
  default = "Ubuntu 22.04"
}
