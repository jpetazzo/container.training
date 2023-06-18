output "cluster_id" {
  value = azurerm_kubernetes_cluster._.id
}

output "has_metrics_server" {
  value = true
}

output "kubeconfig" {
  value     = azurerm_kubernetes_cluster._.kube_config_raw
  sensitive = true
}
