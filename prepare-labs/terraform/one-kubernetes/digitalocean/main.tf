resource "digitalocean_kubernetes_cluster" "_" {
  name = var.cluster_name
  tags = var.common_tags
  # Region is mandatory, so let's provide a default value.
  region  = var.location != null ? var.location : "nyc1"
  version = data.digitalocean_kubernetes_versions._.latest_version

  node_pool {
    name       = "x86"
    tags       = var.common_tags
    size       = local.node_size
    auto_scale = var.max_nodes_per_pool > var.min_nodes_per_pool
    min_nodes  = var.min_nodes_per_pool
    max_nodes  = max(var.min_nodes_per_pool, var.max_nodes_per_pool)
  }

}

data "digitalocean_kubernetes_versions" "_" {
}
