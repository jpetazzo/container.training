data "oci_containerengine_cluster_kube_config" "_" {
  cluster_id = oci_containerengine_cluster._.id
}

output "kubeconfig" {
  value = data.oci_containerengine_cluster_kube_config._.content
}

output "cluster_id" {
  value = oci_containerengine_cluster._.id
}

output "has_metrics_server" {
  value = false
}
