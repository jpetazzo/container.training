terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "1.22.0"
    }
  }
}

provider "digitalocean" {
  token = yamldecode(file("~/.config/doctl/config.yaml"))["access-token"]
}
