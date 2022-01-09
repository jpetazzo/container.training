resource "digitalocean_kubernetes_cluster" "_" {
  name    = var.cluster_name
  tags    = local.common_tags
  region  = var.region
  version = var.k8s_version

  node_pool {
    name       = "x86"
    tags       = local.common_tags
    size       = local.node_type
    auto_scale = true
    min_nodes  = var.min_nodes_per_pool
    max_nodes  = max(var.min_nodes_per_pool, var.max_nodes_per_pool)
  }

}
