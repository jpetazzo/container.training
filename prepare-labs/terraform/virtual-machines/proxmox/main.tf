data "proxmox_virtual_environment_nodes" "_" {}

data "proxmox_virtual_environment_vms" "_" {
  filter {
    name   = "template"
    values = [true]
  }
}

data "proxmox_virtual_environment_vms" "templates" {
  for_each = toset(data.proxmox_virtual_environment_nodes._.names)
  tags     = ["ubuntu"]
  filter {
    name   = "node_name"
    values = [each.value]
  }
  filter {
    name   = "template"
    values = [true]
  }
}

locals {
  pve_nodes       = data.proxmox_virtual_environment_nodes._.names
  pve_node        = { for k, v in local.nodes : k => local.pve_nodes[v.node_index % length(local.pve_nodes)] }
  pve_template_id = { for k, v in local.nodes : k => data.proxmox_virtual_environment_vms.templates[local.pve_node[k]].vms[0].vm_id }
}

resource "proxmox_virtual_environment_vm" "_" {
  for_each        = local.nodes
  node_name       = local.pve_node[each.key]
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
  #  datastore_id = var.proxmox_storage
  #  file_id = proxmox_virtual_environment_file._.id
  #  interface = "scsi0"
  #  size = 30
  #  discard = "on"
  #}
  ### Strategy 1: clone from shared storage
  #clone {
  #  vm_id     = var.proxmox_template_vm_id
  #  node_name = var.proxmox_template_node_name
  #  full      = false
  #}
  ### Strategy 2: clone from local storage
  ### (requires that the template exists on each node)
  clone {
    vm_id     = local.pve_template_id[each.key]
    node_name = local.pve_node[each.key]
    full      = false
  }
  agent {
    enabled = true
  }
  initialization {
    datastore_id = var.proxmox_storage
    user_account {
      username = "ubuntu"
      keys     = [trimspace(tls_private_key.ssh.public_key_openssh)]
    }
    ip_config {
      ipv4 {
        address = "dhcp"
      }
      ipv6 {
        address = "dhcp"
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
    key => [for addr in flatten(concat(
      proxmox_virtual_environment_vm._[key].ipv6_addresses,
      proxmox_virtual_environment_vm._[key].ipv4_addresses,
      ["ERROR"])) :
    addr if addr != "127.0.0.1" && addr != "::1"][0]
  }
}

