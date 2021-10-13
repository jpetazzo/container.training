resource "linode_lke_cluster" "_" {
  label       = var.cluster_name
  tags        = var.common_tags
  region      = var.region
  k8s_version = var.k8s_version

  pool {
    type  = local.node_type
    count = var.min_nodes_per_pool
    autoscaler {
      min = var.min_nodes_per_pool
      max = max(var.min_nodes_per_pool, var.max_nodes_per_pool)
    }
  }

}

