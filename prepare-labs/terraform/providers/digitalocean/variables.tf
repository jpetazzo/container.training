variable "node_sizes" {
  type = map(any)
  default = {
    S = "s-1vcpu-2gb"
    M = "s-2vcpu-4gb"
    L = "s-4vcpu-8gb"
  }
}

variable "location" {
  type    = string
  default = "lon1"
}
