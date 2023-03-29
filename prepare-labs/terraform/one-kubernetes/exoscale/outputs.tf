output "cluster_id" {
  value = exoscale_sks_cluster._.id
}

output "has_metrics_server" {
  value = true
}

output "kubeconfig" {
  value     = exoscale_sks_kubeconfig._.kubeconfig
  sensitive = true
}
