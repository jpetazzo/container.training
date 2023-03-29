terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.45.0"
    }
  }
}

provider "openstack" {
  user_name   = var.user
  tenant_name = var.tenant
  domain_name = var.domain
  password    = var.password
  auth_url    = var.auth_url
}

variable "user" {}
variable "tenant" {}
variable "domain" {}
variable "password" {}
variable "auth_url" {}

// For example: "Public training floating"
variable "pool" {
  type = string
}

// For example: "74e32174-cf09-452f-bda0-2bdfe074e251"
variable "external_network_id" {
  type = string
}

variable "image" {
  type = string
}

variable "node_sizes" {
  type    = map(any)
  default = {}
}

variable "location" {
  type    = string
  default = ""
}
