terraform {
  required_version = ">= 1"
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
    }
  }
}

provider "digitalocean" {
  token = yamldecode(file("~/.config/doctl/config.yaml"))["access-token"]
}