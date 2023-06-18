resource "ovh_cloud_project_kube" "_" {
  name    = var.cluster_name
  region  = var.location
  version = local.k8s_version
}

resource "ovh_cloud_project_kube_nodepool" "_" {
  kube_id       = ovh_cloud_project_kube._.id
  name          = "x86"
  flavor_name   = local.node_size
  desired_nodes = var.min_nodes_per_pool
  min_nodes     = var.min_nodes_per_pool
  max_nodes     = var.max_nodes_per_pool
}

locals {
  k8s_version = "1.26"
}
