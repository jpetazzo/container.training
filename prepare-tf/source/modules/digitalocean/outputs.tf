output "kubeconfig" {
  value = digitalocean_kubernetes_cluster._.kube_config.0.raw_config
}

output "cluster_id" {
  value = digitalocean_kubernetes_cluster._.id
}

output "has_metrics_server" {
  value = false
}
