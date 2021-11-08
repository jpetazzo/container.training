resource "openstack_networking_secgroup_v2" "full_access" {
  name = "${var.prefix} - full access"
}

resource "openstack_networking_secgroup_rule_v2" "full_access" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = ""
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.full_access.id
}

