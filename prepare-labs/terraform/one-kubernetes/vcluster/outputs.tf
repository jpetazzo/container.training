output "cluster_id" {
  value = var.cluster_name
}

output "has_metrics_server" {
  value = true
}

output "kubeconfig" {
  sensitive = true
  value     = local.kubeconfig
}

data "kubernetes_secret_v1" "kubeconfig" {
  depends_on = [helm_release._]
  metadata {
    name      = "vc-vcluster"
    namespace = var.cluster_name
  }
}

data "kubernetes_service_v1" "vcluster" {
  depends_on = [helm_release._]
  metadata {
    name      = "vcluster"
    namespace = var.cluster_name
  }
}

data "kubernetes_nodes" "_" {
}

# In the variables below, we use "traditional" virtualization terms, i.e.:
# host = "real" Kubernetes cluster
# guest = virtual Kubernetes cluster

locals {
  kubeconfig_raw           = data.kubernetes_secret_v1.kubeconfig.data.config
  node_external_ip         = data.kubernetes_nodes._.nodes[0].metadata[0].labels.external_ip
  node_port                = data.kubernetes_service_v1.vcluster.spec[0].port[0].node_port
  host_api_server_url      = yamldecode(file("~/kubeconfig")).clusters[0].cluster.server
  host_api_server_host     = regex("https://([^:]+):", local.host_api_server_url)[0]
  guest_api_server_host    = local.node_external_ip
  guest_api_server_port    = local.node_port
  guest_api_server_url_new = "https://${local.guest_api_server_host}:${local.guest_api_server_port}"
  guest_api_server_url_old = yamldecode(local.kubeconfig_raw).clusters[0].cluster.server
  kubeconfig               = replace(local.kubeconfig_raw, local.guest_api_server_url_old,  local.guest_api_server_url_new)
}
