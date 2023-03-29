resource "linode_instance" "_" {
  for_each        = local.nodes
  label           = each.value.node_name
  region          = var.location
  type            = each.value.node_size
  authorized_keys = [trimspace(tls_private_key.ssh.public_key_openssh)]
  image           = "linode/ubuntu22.04"
}

locals {
  ip_addresses = {
    for key, value in local.nodes :
    key => linode_instance._[key].ip_address
  }
}
