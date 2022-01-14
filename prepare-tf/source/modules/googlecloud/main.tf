resource "google_container_cluster" "_" {
  name               = var.cluster_name
  project            = local.project
  location           = local.location
  min_master_version = var.k8s_version

  # To deploy private clusters, uncomment the section below,
  # and uncomment the block in network.tf.
  # Private clusters require extra resources (Cloud NAT,
  # router, network, subnet) and the quota for some of these
  # resources is fairly low on GCP; so if you want to deploy
  # a lot of private clusters (more than 10), you can use these
  # blocks as a base but you will probably have to refactor
  # things quite a bit (you will at least need to define a single
  # shared router and use it across all the clusters).
  /*
  network    = google_compute_network._.name
  subnetwork = google_compute_subnetwork._.name

  private_cluster_config {
    enable_private_nodes = true
    # This must be set to "false".
    # (Otherwise, access to the public endpoint is disabled.)
    enable_private_endpoint = false
    # This must be set to a /28.
    # I think it shouldn't collide with the pod network subnet.
    master_ipv4_cidr_block = "10.255.255.0/28"
  }
  # Private clusters require "VPC_NATIVE" networking mode
  # (as opposed to the legacy "ROUTES").
  networking_mode = "VPC_NATIVE"
  # ip_allocation_policy is required for VPC_NATIVE clusters.
  ip_allocation_policy {
    # This is the block that will be used for pods.
    cluster_ipv4_cidr_block = "10.0.0.0/12"
    # The services block is optional
    # (GKE will pick one automatically).
    #services_ipv4_cidr_block = ""
  }
  */

  node_pool {
    name = "x86"
    node_config {
      tags         = var.common_tags
      machine_type = local.node_type
    }
    initial_node_count = var.min_nodes_per_pool
    autoscaling {
      min_node_count = var.min_nodes_per_pool
      max_node_count = max(var.min_nodes_per_pool, var.max_nodes_per_pool)
    }
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

