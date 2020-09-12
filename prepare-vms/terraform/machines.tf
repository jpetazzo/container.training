resource "openstack_compute_instance_v2" "machine" {
  count           = "${var.count}" 
  name            = "${format("%s-%04d", "${var.prefix}", count.index+1)}"
  image_name      = "Ubuntu 18.04.4 20200324"
  flavor_name     = "${var.flavor}"
  security_groups = ["${openstack_networking_secgroup_v2.full_access.name}"]
  key_pair        = "${openstack_compute_keypair_v2.ssh_deploy_key.name}"

  network {
    name        = "${openstack_networking_network_v2.internal.name}"
    fixed_ip_v4 = "${cidrhost("${openstack_networking_subnet_v2.internal.cidr}", count.index+10)}"
  }
}

resource "openstack_compute_floatingip_v2" "machine" {
  count = "${var.count}"
  # This is something provided to us by Enix when our tenant was provisioned.
  pool = "Public Floating"
}

resource "openstack_compute_floatingip_associate_v2" "machine" {
  count       = "${var.count}"
  floating_ip = "${openstack_compute_floatingip_v2.machine.*.address[count.index]}"
  instance_id = "${openstack_compute_instance_v2.machine.*.id[count.index]}"
  fixed_ip    = "${cidrhost("${openstack_networking_subnet_v2.internal.cidr}", count.index+10)}"
}

output "ip_addresses" {
  value = "${join("\n", openstack_compute_floatingip_v2.machine.*.address)}"
}

variable "flavor" {}
