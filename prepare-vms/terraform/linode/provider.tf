terraform {
  required_version = ">= 1"
  required_providers {
    linode = {
      source = "linode/linode"
    }
  }
}

provider "linode" {
  token = regex("\ntoken *= *([0-9a-f]+)\n", file("~/.config/linode-cli"))[0]
}