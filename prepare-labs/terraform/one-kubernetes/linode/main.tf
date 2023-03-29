resource "linode_lke_cluster" "_" {
  label = var.cluster_name
  tags  = var.common_tags
  # "region" is mandatory, so let's provide a default value if none was given.
  region      = var.location != null ? var.location : "eu-central"
  k8s_version = data.linode_lke_versions._.versions[0].id

  pool {
    type  = local.node_size
    count = var.min_nodes_per_pool
    autoscaler {
      min = var.min_nodes_per_pool
      max = max(var.min_nodes_per_pool, var.max_nodes_per_pool)
    }
  }

}

data "linode_lke_versions" "_" {
}

# FIXME: sort the versions to be sure that we get the most recent one?
# (We don't know in which order they are returned by the provider.)
