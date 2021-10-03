resource "scaleway_k8s_cluster" "my_cluster" {
  name        = var.cluster_name
  tags        = var.common_tags
  version     = var.k8s_version
  cni         = var.cni
}

resource "scaleway_k8s_pool" "my_pool" {
  cluster_id  = scaleway_k8s_cluster.my_cluster.id
  name        = "pool-0"
  tags        = var.common_tags
  node_type   = var.node_type
  size        = var.pool_size
  min_size    = var.pool_min_size
  max_size    = var.pool_max_size
  autoscaling = true
  autohealing = true
}
