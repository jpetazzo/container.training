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
s-1vcpu-2gb
s-2vcpu-2gb
s-2vcpu-4gb
s-4vcpu-8gb
*/

variable "size" {
  type    = string
  default = "s-2vcpu-4gb"
}

/* doctl compute region list */
variable "location" {
  type    = string
  default = "lon1"
}
