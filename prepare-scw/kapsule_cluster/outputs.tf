output "kubeconfig" {
  value       = scaleway_k8s_cluster.my_cluster.kubeconfig
}

output "cluster_id" {
  value       = scaleway_k8s_cluster.my_cluster.id
}

output "wildcard_dns" {
  value       = scaleway_k8s_cluster.my_cluster.wildcard_dns
}
