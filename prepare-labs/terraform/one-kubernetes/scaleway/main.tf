resource "scaleway_vpc_private_network" "_" {
}

# This is a kind of hack to use a custom security group with Kapsulse.
# See https://www.scaleway.com/en/docs/containers/kubernetes/reference-content/secure-cluster-with-private-network/

resource "scaleway_instance_security_group" "_" {
  name                    = "kubernetes ${split("/", scaleway_k8s_cluster._.id)[1]}"
  inbound_default_policy  = "accept"
  outbound_default_policy = "accept"
}

resource "scaleway_k8s_cluster" "_" {
  name                        = var.cluster_name
  tags                        = var.common_tags
  version                     = local.k8s_version
  type                        = "kapsule"
  cni                         = "cilium"
  delete_additional_resources = true
  private_network_id          = scaleway_vpc_private_network._.id
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
  depends_on = [ scaleway_instance_security_group._ ]
}

data "scaleway_k8s_version" "_" {
  name = "latest"
}

locals {
  k8s_version = data.scaleway_k8s_version._.name
}
