output "cluster_id" {
  value = civo_kubernetes_cluster._.id
}

output "has_metrics_server" {
  value = false
}

output "kubeconfig" {
  value     = civo_kubernetes_cluster._.kubeconfig
  sensitive = true
}
