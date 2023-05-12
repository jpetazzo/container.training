resource "openstack_compute_instance_v2" "_" {
  for_each    = local.nodes
  name        = each.value.node_name
  image_name  = var.image
  flavor_name = each.value.node_size
  key_pair = openstack_compute_keypair_v2._.name
  network {
    port = openstack_networking_port_v2._[each.key].id
  }
}

resource "openstack_networking_port_v2" "_" {
  for_each              = local.nodes
  network_id            = openstack_networking_network_v2._.id
  port_security_enabled = false
  fixed_ip {
    subnet_id = openstack_networking_subnet_v2._.id
  }
}

resource "openstack_compute_floatingip_v2" "_" {
  for_each = local.nodes
  pool     = var.pool
}

resource "openstack_compute_floatingip_associate_v2" "_" {
  for_each    = local.nodes
  floating_ip = openstack_compute_floatingip_v2._[each.key].address
  instance_id = openstack_compute_instance_v2._[each.key].id
  fixed_ip    = openstack_compute_instance_v2._[each.key].network[0].fixed_ip_v4
}

locals {
  ip_addresses = {
    for key, value in local.nodes :
    key => openstack_compute_floatingip_v2._[key].address
  }
}

resource "openstack_compute_keypair_v2" "_" {
  name       = var.tag
  public_key = tls_private_key.ssh.public_key_openssh
}
