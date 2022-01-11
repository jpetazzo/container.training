resource "scaleway_k8s_cluster" "_" {
  name                        = var.cluster_name
  region                      = var.location
  tags                        = var.common_tags
  version                     = var.k8s_version
  cni                         = var.cni
  delete_additional_resources = true
}

resource "scaleway_k8s_pool" "_" {
  cluster_id  = scaleway_k8s_cluster._.id
  name        = "x86"
  tags        = var.common_tags
  node_type   = local.node_type
  size        = var.min_nodes_per_pool
  min_size    = var.min_nodes_per_pool
  max_size    = max(var.min_nodes_per_pool, var.max_nodes_per_pool)
  autoscaling = true
  autohealing = true
}
