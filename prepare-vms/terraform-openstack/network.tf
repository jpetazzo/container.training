resource "openstack_networking_network_v2" "internal" {
  name           = var.prefix
}

resource "openstack_networking_subnet_v2" "internal" {
  name            = var.prefix
  network_id      = openstack_networking_network_v2.internal.id
  cidr            = "10.10.0.0/16"
  ip_version      = 4
  dns_nameservers = ["1.1.1.1"]
}

resource "openstack_networking_router_v2" "router" {
  name                = var.prefix
  external_network_id = "15f0c299-1f50-42a6-9aff-63ea5b75f3fc"
}

resource "openstack_networking_router_interface_v2" "router_internal" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.internal.id
}


