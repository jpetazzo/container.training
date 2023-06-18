output "cluster_id" {
  value = ovh_cloud_project_kube._.id
}

output "has_metrics_server" {
  value = false
}

output "kubeconfig" {
  sensitive = true
  value     = ovh_cloud_project_kube._.kubeconfig
}
