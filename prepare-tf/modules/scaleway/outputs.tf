output "kubeconfig" {
  value = scaleway_k8s_cluster._.kubeconfig.0.config_file
}

output "cluster_id" {
  value = scaleway_k8s_cluster._.id
}
