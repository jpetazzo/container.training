resource "linode_lke_cluster" "_" {
  label = var.cluster_name
  tags  = var.common_tags
  # "region" is mandatory, so let's provide a default value if none was given.
  region      = var.location != null ? var.location : "eu-central"
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
