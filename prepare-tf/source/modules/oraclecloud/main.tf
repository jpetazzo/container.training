resource "oci_identity_compartment" "_" {
  name          = var.cluster_name
  description   = var.cluster_name
  enable_delete = true
}

locals {
  compartment_id = oci_identity_compartment._.id
}

data "oci_identity_availability_domains" "_" {
  compartment_id = local.compartment_id
}

data "oci_core_images" "_" {
  for_each                 = local.pools
  compartment_id           = local.compartment_id
  operating_system         = "Oracle Linux"
  operating_system_version = "7.9"
  shape                    = each.value.shape
}

resource "oci_containerengine_cluster" "_" {
  compartment_id     = local.compartment_id
  kubernetes_version = var.k8s_version
  name               = "tf-oke"
  vcn_id             = oci_core_vcn._.id
  options {
    service_lb_subnet_ids = [oci_core_subnet.loadbalancers.id]
  }
  endpoint_config {
    is_public_ip_enabled = true
    subnet_id            = oci_core_subnet.controlplane.id
  }
}

resource "oci_containerengine_node_pool" "_" {
  for_each           = local.pools
  cluster_id         = oci_containerengine_cluster._.id
  compartment_id     = local.compartment_id
  kubernetes_version = var.k8s_version
  name               = each.key
  node_shape         = each.value.shape
  node_shape_config {
    memory_in_gbs = local.node_type.memory_in_gbs
    ocpus         = local.node_type.ocpus
  }
  node_config_details {
    size = var.min_nodes_per_pool
    placement_configs {
      availability_domain = data.oci_identity_availability_domains._.availability_domains[0].name
      subnet_id           = oci_core_subnet.nodes.id
    }
  }
  node_source_details {
    image_id    = data.oci_core_images._[each.key].images[0].id
    source_type = "image"
  }
}
