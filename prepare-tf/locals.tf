resource "random_string" "_" {
  length  = 5
  special = false
  upper   = false
}

resource "time_static" "_" {}

locals {
  tag = format("tf-%s-%s", formatdate("YYYY-MM-DD-hh-mm", time_static._.rfc3339), random_string._.result)
  # Common tags to be assigned to all resources
  common_tags = [
    "created-by=terraform",
    "tag=${local.tag}"
  ]
}
