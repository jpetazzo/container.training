terraform {
required_version = ">= 1"
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
