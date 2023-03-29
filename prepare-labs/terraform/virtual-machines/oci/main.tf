resource "oci_identity_compartment" "_" {
  name          = var.tag
  description   = var.tag
  enable_delete = true
}

locals {
  compartment_id = oci_identity_compartment._.id
}

data "oci_identity_availability_domains" "_" {
  compartment_id = local.compartment_id
}

data "oci_core_images" "_" {
  compartment_id           = local.compartment_id
  shape                    = local.shape
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  #operating_system         = "Oracle Linux"
  #operating_system_version = "7.9"
}

resource "oci_core_instance" "_" {
  for_each            = local.nodes
  display_name        = each.value.node_name
  availability_domain = data.oci_identity_availability_domains._.availability_domains[var.availability_domain].name
  compartment_id      = local.compartment_id
  shape               = local.shape
  shape_config {
    memory_in_gbs = local.memory_in_gbs
    ocpus         = local.ocpus
  }
  source_details {
    source_id   = data.oci_core_images._.images[0].id
    source_type = "image"
  }
  create_vnic_details {
    subnet_id = oci_core_subnet._.id
  }
  metadata = {
    ssh_authorized_keys = tls_private_key.ssh.public_key_openssh
  }
}

locals {
  ip_addresses = {
    for key, value in local.nodes :
    key => oci_core_instance._[key].public_ip
  }
}
