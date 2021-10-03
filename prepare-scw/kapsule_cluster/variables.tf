variable "cluster_name" {
  type    = string
  default = "deployed-with-terraform"  
}

variable "cni" {
  type    = string
  default = "cilium"
}

variable "common_tags" {
  type    = list(string)
  default = []
}

variable "k8s_version" {
  type    = string
  default = "1.22.2"
}

variable "node_type" {
  type    = string
  default = "DEV1-M"
}

variable "pool_size" {
  type    = number
  default = 2
}

variable "pool_min_size" {
  type    = number
  default = 1
}

variable "pool_max_size" {
  type    = number
  default = 5
}
