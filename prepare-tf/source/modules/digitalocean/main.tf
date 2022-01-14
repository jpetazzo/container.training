resource "digitalocean_kubernetes_cluster" "_" {
  name = var.cluster_name
  tags = var.common_tags
  # Region is mandatory, so let's provide a default value.
  region  = var.location != null ? var.location : "nyc1"
  version = var.k8s_version

  node_pool {
    name       = "x86"
    tags       = var.common_tags
    size       = local.node_type
    auto_scale = true
    min_nodes  = var.min_nodes_per_pool
    max_nodes  = max(var.min_nodes_per_pool, var.max_nodes_per_pool)
  }

}
