variable "prefix" {
  type    = string
  default = "provisioned-with-terraform"
}

variable "how_many_nodes" {
  type    = number
  default = 2
}

locals {
  authorized_keys = split("\n", trimspace(file("~/.ssh/id_rsa.pub")))
}

/*
Available sizes:
"g6-standard-1" # CPU=1 RAM=2
"g6-standard-2" # CPU=2 RAM=4
"g6-standard-4" # CPU=4 RAM=8
"g6-standard-6" # CPU=6 RAM=16
"g6-standard-8" # CPU=8 RAM=32
*/

variable "size" {
  type    = string
  default = "g6-standard-2"
}

variable "location" {
  type    = string
  default = "eu-west"
}
