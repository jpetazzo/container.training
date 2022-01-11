data "google_client_config" "_" {}

output "kubeconfig" {
  value = <<-EOT
    apiVersion: v1
    kind: Config
    current-context: ${google_container_cluster._.name}
    clusters:
    - name: ${google_container_cluster._.name}
      cluster:
        server: https://${google_container_cluster._.endpoint}
        certificate-authority-data: ${google_container_cluster._.master_auth[0].cluster_ca_certificate}
    contexts:
    - name: ${google_container_cluster._.name}
      context:
        cluster: ${google_container_cluster._.name}
        user: client-token
    users:
    - name: client-cert
      user:
        client-key-data: ${google_container_cluster._.master_auth[0].client_key}
        client-certificate-data: ${google_container_cluster._.master_auth[0].client_certificate}
    - name: client-token
      user:
        token: ${data.google_client_config._.access_token}
    EOT
}

output "cluster_id" {
  value = google_container_cluster._.id
}

output "has_metrics_server" {
  value = true
}
