provider "digitalocean" {
  token = yamldecode(file("~/.config/doctl/config.yaml"))["access-token"]
}
