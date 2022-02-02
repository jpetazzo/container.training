terraform {
  required_version = ">= 1"
  required_providers {
    openstack = {
      source = "hashicorp/oci"
    version = "4.48.0" }
  }
}
