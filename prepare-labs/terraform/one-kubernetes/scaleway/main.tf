resource "scaleway_k8s_cluster" "_" {
  name = var.cluster_name
  #region                     = var.location
  tags                        = var.common_tags
  version                     = local.k8s_version
  cni                         = "cilium"
  delete_additional_resources = true
}

resource "scaleway_k8s_pool" "_" {
  cluster_id  = scaleway_k8s_cluster._.id
  name        = "x86"
  tags        = var.common_tags
  node_type   = local.node_size
  size        = var.min_nodes_per_pool
  min_size    = var.min_nodes_per_pool
  max_size    = var.max_nodes_per_pool
  autoscaling = var.max_nodes_per_pool > var.min_nodes_per_pool
  autohealing = true
}

data "scaleway_k8s_version" "_" {
  name = "latest"
}

locals {
  k8s_version = data.scaleway_k8s_version._.name
}
