# Since node size needs to be a string...
# To indicate number of CPUs + RAM, just pass it as a string with a space between them.
# RAM is in megabytes.
variable "node_sizes" {
  type = map(any)
  default = {
    S = "1 2048"
    M = "2 4096"
    L = "3 8192"
  }
}
