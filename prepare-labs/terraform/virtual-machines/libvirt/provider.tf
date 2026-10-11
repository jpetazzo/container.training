terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.9.7"
    }
  }
}

provider "libvirt" {
  uri = var.libvirt_uri
}
