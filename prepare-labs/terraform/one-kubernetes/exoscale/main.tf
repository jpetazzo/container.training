resource "exoscale_sks_cluster" "_" {
  zone          = var.location
  name          = var.cluster_name
  service_level = "starter"
}

resource "exoscale_sks_nodepool" "_" {
  cluster_id    = exoscale_sks_cluster._.id
  zone          = exoscale_sks_cluster._.zone
  name          = var.cluster_name
  instance_type = local.node_size
  size          = var.min_nodes_per_pool
}

resource "exoscale_sks_kubeconfig" "_" {
  cluster_id = exoscale_sks_cluster._.id
  zone       = exoscale_sks_cluster._.zone
  user       = "kubernetes-admin"
  groups     = ["system:masters"]
}