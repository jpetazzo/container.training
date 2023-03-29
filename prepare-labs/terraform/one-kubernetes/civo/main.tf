# As of March 2023, the default type ("k3s") only supports up
# to Kubernetes 1.23, which belongs to a museum.
# So let's use Talos, which supports up to 1.25.

resource "civo_kubernetes_cluster" "_" {
  name         = var.cluster_name
  firewall_id  = civo_firewall._.id
  cluster_type = "talos"
  pools {
    size       = local.node_size
    node_count = var.min_nodes_per_pool
  }
}

resource "civo_firewall" "_" {
  name = var.cluster_name
}
