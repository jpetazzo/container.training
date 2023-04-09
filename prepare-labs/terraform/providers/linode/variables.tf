/*
Available sizes:
"g6-standard-1" # CPU=1 RAM=2
"g6-standard-2" # CPU=2 RAM=4
"g6-standard-4" # CPU=4 RAM=8
"g6-standard-6" # CPU=6 RAM=16
"g6-standard-8" # CPU=8 RAM=32
*/
variable "node_sizes" {
  type = map(any)
  default = {
    S = "g6-standard-1"
    M = "g6-standard-2"
    L = "g6-standard-4"
  }
}

variable "location" {
  type    = string
  default = "eu-west"
}
