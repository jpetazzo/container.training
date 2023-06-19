resource "oci_identity_compartment" "_" {
  name          = var.cluster_name
  description   = var.cluster_name
  enable_delete = true
}

data "oci_containerengine_cluster_option" "_" {
  cluster_option_id = "all"
}

locals {
  compartment_id     = oci_identity_compartment._.id
  kubernetes_version = data.oci_containerengine_cluster_option._.kubernetes_versions[0]
  images = [
    for image in data.oci_containerengine_node_pool_option._.sources : image
    if can(regex("OKE", image.source_name))
    && can(regex(substr(local.kubernetes_version, 1, -1), image.source_name))
    && !can(regex("GPU", image.source_name))
    && !can(regex("aarch64", image.source_name))
  ]

}

data "oci_identity_availability_domains" "_" {
  compartment_id = local.compartment_id
}

data "oci_containerengine_node_pool_option" "_" {
  compartment_id      = local.compartment_id
  node_pool_option_id = oci_containerengine_cluster._.id
}

resource "oci_containerengine_cluster" "_" {
  compartment_id     = local.compartment_id
  kubernetes_version = local.kubernetes_version
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
  cluster_id         = oci_containerengine_cluster._.id
  compartment_id     = local.compartment_id
  kubernetes_version = local.kubernetes_version
  name               = "pool"
  node_shape         = local.shape
  node_shape_config {
    memory_in_gbs = local.memory_in_gbs
    ocpus         = local.ocpus
  }
  node_config_details {
    size = var.min_nodes_per_pool
    placement_configs {
      availability_domain = data.oci_identity_availability_domains._.availability_domains[0].name
      subnet_id           = oci_core_subnet.nodes.id
    }
  }
  node_source_details {
    image_id    = local.images[0].image_id
    source_type = "image"
  }
}
