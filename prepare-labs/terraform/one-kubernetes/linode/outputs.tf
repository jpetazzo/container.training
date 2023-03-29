output "cluster_id" {
  value = linode_lke_cluster._.id
}

output "has_metrics_server" {
  value = false
}

output "kubeconfig" {
  value     = base64decode(linode_lke_cluster._.kubeconfig)
  sensitive = true
}
