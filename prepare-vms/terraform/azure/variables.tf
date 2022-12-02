variable "prefix" {
  type    = string
  default = "provisioned-with-terraform"
}

variable "how_many_nodes" {
  type    = number
  default = 2
}

locals {
  authorized_keys = file("~/.ssh/id_rsa.pub")
}

/*
Available sizes:
"Standard_D11_v2" # CPU=2 RAM=14
"Standard_F4s_v2" # CPU=4 RAM=8
"Standard_D1_v2"  # CPU=1 RAM=3.5
"Standard_B1ms"   # CPU=1 RAM=2
"Standard_B2s"    # CPU=2 RAM=4
*/

variable "size" {
  type    = string
  default = "Standard_F4s_v2"
}

variable "location" {
  type    = string
  default = "South Africa North"
}
