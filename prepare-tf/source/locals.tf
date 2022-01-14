resource "random_string" "_" {
  length  = 4
  number  = false
  special = false
  upper   = false
}

resource "time_static" "_" {}

locals {
  timestamp = formatdate("YYYY-MM-DD-hh-mm", time_static._.rfc3339)
  tag       = random_string._.result
  # Common tags to be assigned to all resources
  common_tags = [
    "created-by-terraform",
    format("created-at-%s", local.timestamp),
    format("created-for-%s", local.tag)
  ]
}
