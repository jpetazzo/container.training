module "kapsule_cluster" {
  count         = var.how_many_clusters
  source        = "./kapsule_cluster"
  cluster_name  = format("tf-%s-%03d", random_string.tag.result, count.index + 101)
  pool_size     = var.nodes_per_cluster
  pool_min_size = var.nodes_per_cluster
}

output "kubectl_config" {
  value = format("scw k8s kubeconfig install %s", split("/", module.kapsule_cluster.0.cluster_id)[1])
}

resource "random_string" "tag" {
  length = 5
  special = false
  upper = false
}

resource "local_file" "stage2" {
  filename = "${path.module}/stage2/main.tf"
  content = templatefile(
    "${path.module}/stage2.tmpl",
    { count = var.how_many_clusters }
  )
}

resource "local_file" "kubeconfig" {
  count    = var.how_many_clusters
  filename = format("%s/stage2/kubeconfig.%03d", path.module, count.index + 101)
  content  = module.kapsule_cluster[count.index].kubeconfig.0.config_file
}

resource "local_file" "wildcard_dns" {
  count    = var.how_many_clusters
  filename = format("%s/stage2/wildcard_dns.%03d", path.module, count.index + 101)
  content  = trimprefix(module.kapsule_cluster[count.index].wildcard_dns, "*.")
}
