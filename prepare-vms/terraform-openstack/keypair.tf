resource "openstack_compute_keypair_v2" "ssh_deploy_key" {
  name       = var.prefix
  public_key = file("~/.ssh/id_rsa.pub")
}

