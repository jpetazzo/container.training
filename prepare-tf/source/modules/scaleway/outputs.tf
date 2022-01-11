output "kubeconfig" {
  value = scaleway_k8s_cluster._.kubeconfig.0.config_file
}

output "cluster_id" {
  value = scaleway_k8s_cluster._.id
}

output "has_metrics_server" {
  value = sort([var.k8s_version, "1.22"])[0] == "1.22"
}
