resource "google_container_cluster" "_" {
  name               = var.cluster_name
  project            = "prepare-tf"
  location           = "europe-north1-a"
  min_master_version = var.k8s_version
  initial_node_count = var.min_nodes_per_pool
  #max_size    = max(var.min_nodes_per_pool, var.max_nodes_per_pool)
  #autoscaling = true
  #autohealing = true

  node_config {
    tags         = var.common_tags
    machine_type = local.node_type
  }

  # This is not strictly necessary.
  # We'll see if we end up using it.
  # (If it is removed, make sure to also remove the corresponding
  # key+cert variables from outputs.tf!)
  master_auth {
    client_certificate_config {
      issue_client_certificate = true
    }
  }
}
