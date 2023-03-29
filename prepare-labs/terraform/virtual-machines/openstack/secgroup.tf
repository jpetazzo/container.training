resource "openstack_networking_secgroup_v2" "_" {
  name = var.tag
}

resource "openstack_networking_secgroup_rule_v2" "_" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = ""
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2._.id
}
