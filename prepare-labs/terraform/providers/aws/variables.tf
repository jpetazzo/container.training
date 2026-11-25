variable "node_sizes" {
  type = map(any)
  default = {
    S = "t3.small"
    M = "t3.medium"
    L = "t3.large"
  }
}

variable "location" {
  type    = string
  default = "eu-north-1"
}

# The Ubuntu AMI root disk is only 8 GB. Kubernetes images, Docker,
# and the day 2 security tools (e.g. trivy DBs) need more space.
variable "root_disk_size" {
  type    = number
  default = 30
}
