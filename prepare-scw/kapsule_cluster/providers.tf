terraform {
  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "2.1.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.0.3"
    }
    local = {
      source = "hashicorp/local"
      version = "2.1.0"
    }
  }
  required_version = ">= 0.14"
}
