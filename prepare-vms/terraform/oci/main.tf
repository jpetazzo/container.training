resource "oci_identity_compartment" "_" {
  name          = var.prefix
  description   = var.prefix
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
  shape                    = var.shape
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "20.04"
  #operating_system         = "Oracle Linux"
  #operating_system_version = "7.9"
}

resource "oci_core_instance" "_" {
  count               = var.how_many_nodes
  display_name        = format("%s-%04d", var.prefix, count.index + 1)
  availability_domain = data.oci_identity_availability_domains._.availability_domains[var.availability_domain].name
  compartment_id      = local.compartment_id
  shape               = var.shape
  shape_config {
    memory_in_gbs = var.memory_in_gbs_per_node
    ocpus         = var.ocpus_per_node
  }
  source_details {
    source_id   = data.oci_core_images._.images[0].id
    source_type = "image"
  }
  create_vnic_details {
    subnet_id = oci_core_subnet._.id
  }
  metadata = {
    ssh_authorized_keys = local.authorized_keys
  }
}

output "ip_addresses" {
  value = join("", formatlist("%s\n", oci_core_instance._.*.public_ip))
}
