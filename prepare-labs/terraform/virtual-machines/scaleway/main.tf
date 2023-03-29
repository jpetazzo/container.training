resource "scaleway_instance_server" "_" {
  for_each          = local.nodes
  type              = each.value.node_size
  image             = "ubuntu_jammy"
  zone              = var.location
  name              = each.value.node_name
  enable_ipv6       = true
  enable_dynamic_ip = true
  tags              = [format("AUTHORIZED_KEY=%s", replace(trimspace(tls_private_key.ssh.public_key_openssh), " ", "_"))]
}

locals {
  ip_addresses = {
    for key, value in local.nodes :
    key => scaleway_instance_server._[key].public_ip
  }
}
