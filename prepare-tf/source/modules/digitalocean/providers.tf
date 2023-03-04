terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.12.1"
    }
  }
}

provider "digitalocean" {
  token = yamldecode(file("~/.config/doctl/config.yaml"))["access-token"]
}
