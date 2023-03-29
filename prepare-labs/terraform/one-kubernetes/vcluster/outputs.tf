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

locals {
  kubeconfig_raw        = data.kubernetes_secret_v1.kubeconfig.data.config
  node_port             = data.kubernetes_service_v1.vcluster.spec[0].port[0].node_port
  outer_api_server_url  = yamldecode(file("~/kubeconfig")).clusters[0].cluster.server
  outer_api_server_host = regex("https://([^:]+):", local.outer_api_server_url)[0]
  inner_api_server_host = local.outer_api_server_host
  inner_old_server_url  = yamldecode(local.kubeconfig_raw).clusters[0].cluster.server
  inner_new_server_url  = "https://${local.inner_api_server_host}:${local.node_port}"
  kubeconfig            = replace(local.kubeconfig_raw, local.inner_old_server_url, local.inner_new_server_url)
}