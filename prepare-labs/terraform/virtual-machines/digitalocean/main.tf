resource "digitalocean_droplet" "_" {
  for_each = local.nodes
  name     = each.value.node_name
  region   = var.location
  size     = each.value.node_size
  ssh_keys = [digitalocean_ssh_key._.id]
  image    = "ubuntu-22-04-x64"
}

resource "digitalocean_ssh_key" "_" {
  name       = var.tag
  public_key = tls_private_key.ssh.public_key_openssh
}

locals {
  ip_addresses = {
    for key, value in local.nodes :
    key => digitalocean_droplet._[key].ipv4_address
  }
}
