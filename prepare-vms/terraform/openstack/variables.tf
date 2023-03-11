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

// For example: "Public training floating"
variable "pool" {
  type = string
}

// For example: "74e32174-cf09-452f-bda0-2bdfe074e251"
variable "external_network_id" {
  type = string
}
