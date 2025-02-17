data "proxmox_virtual_environment_nodes" "_" {}

locals {
  pve_nodes = data.proxmox_virtual_environment_nodes._.names
}

resource "proxmox_virtual_environment_vm" "_" {
  node_name       = local.pve_nodes[each.value.node_index % length(local.pve_nodes)]
  for_each        = local.nodes
  name            = each.value.node_name
  tags            = ["container.training", var.tag]
  stop_on_destroy = true
  cpu {
    cores = split(" ", each.value.node_size)[0]
    type  = "x86-64-v2-AES" # recommended for modern CPUs
  }
  memory {
    dedicated = split(" ", each.value.node_size)[1]
  }
  #disk {
  #  datastore_id = "ceph"
  #  file_id = proxmox_virtual_environment_file._.id
  #  interface = "scsi0"
  #  size = 30
  #  discard = "on"
  #}
  clone {
    vm_id     = var.proxmox_template_vm_id
    node_name = var.proxmox_template_node_name
    full      = false
  }
  agent {
    enabled = true
  }
  initialization {
    datastore_id = "ceph"
    user_account {
      username = "ubuntu"
      keys     = [trimspace(tls_private_key.ssh.public_key_openssh)]
    }
    ip_config {
      ipv4 {
        address = "dhcp"
        #gateway =
      }
    }
  }
  network_device {
    bridge = "vmbr0"
  }
  operating_system {
    type = "l26"
  }
}

#resource "proxmox_virtual_environment_download_file" "ubuntu_2404_20250115" {
#  content_type = "iso"
#  datastore_id = "cephfs"
#  node_name    = "pve-lsd-1"
#  url          = "https://cloud-images.ubuntu.com/releases/24.04/release-20250115/ubuntu-24.04-server-cloudimg-amd64.img"
#  file_name    = "ubuntu_2404_20250115.img"
#}
#
#resource "proxmox_virtual_environment_file" "_" {
#  datastore_id = "cephfs"
#  node_name = "pve-lsd-1"
#  source_file {
#    path = "/root/noble-server-cloudimg-amd64.img"
#  }
#}

locals {
  ip_addresses = {
    for key, value in local.nodes :
    key => [for addr in flatten(concat(proxmox_virtual_environment_vm._[key].ipv4_addresses, ["ERROR"])) :
    addr if addr != "127.0.0.1"][0]
  }
}

