resource "hcloud_server" "_" {
  for_each    = local.nodes
  name        = each.value.node_name
  location    = var.location
  server_type = each.value.node_size
  ssh_keys    = [hcloud_ssh_key._.id]
  image       = "ubuntu-22.04"
}

resource "hcloud_ssh_key" "_" {
  name       = var.tag
  public_key = tls_private_key.ssh.public_key_openssh
}

locals {
  ip_addresses = {
    for key, value in local.nodes :
    key => hcloud_server._[key].ipv4_address
  }
}
