/*
By convention we'll use "shape OCPUS GB-RAM"
and we'll split it accordingly.

Available flex shapes:
"VM.Optimized3.Flex"  # Intel Ice Lake
"VM.Standard3.Flex"   # Intel Ice Lake
"VM.Standard.A1.Flex" # Ampere Altra
"VM.Standard.E3.Flex" # AMD Rome
"VM.Standard.E4.Flex" # AMD Milan
*/
variable "node_sizes" {
  type = map(any)
  default = {
    S = "VM.Standard.E4.Flex 1 2"
    M = "VM.Standard.E4.Flex 2 4"
    L = "VM.Standard.E4.Flex 3 8"
  }
}

variable "location" {
  type    = string
  default = null
}

variable "availability_domain" {
  type    = number
  default = 0
}

locals {
  shape         = split(" ", local.node_size)[0]
  ocpus         = split(" ", local.node_size)[1]
  memory_in_gbs = split(" ", local.node_size)[2]
}
