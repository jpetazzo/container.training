resource "openstack_networking_network_v2" "_" {
  name = var.tag
}

resource "openstack_networking_subnet_v2" "_" {
  name            = var.tag
  network_id      = openstack_networking_network_v2._.id
  cidr            = "10.10.0.0/16"
  ip_version      = 4
  dns_nameservers = ["1.1.1.1"]
}

resource "openstack_networking_router_v2" "_" {
  name                = var.tag
  external_network_id = var.external_network_id
}

resource "openstack_networking_router_interface_v2" "_" {
  router_id = openstack_networking_router_v2._.id
  subnet_id = openstack_networking_subnet_v2._.id
}
