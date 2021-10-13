module "clusters" {
  source             = "./modules/scaleway"
  for_each           = local.clusters
  cluster_name       = each.value.cluster_name
  min_nodes_per_pool = var.min_nodes_per_pool
  max_nodes_per_pool = var.max_nodes_per_pool
  enable_arm_pool    = var.enable_arm_pool
  node_size          = var.node_size
  common_tags        = local.common_tags
}

locals {
  clusters = {
    for i in range(101, 101 + var.how_many_clusters) :
    i => {
      cluster_name        = format("%s-%03d", local.tag, i)
      kubeconfig_path     = format("./stage2/kubeconfig.%03d", i)
      dashdash_kubeconfig = format("--kubeconfig=./stage2/kubeconfig.%03d", i)
      externalips_path    = format("./stage2/externalips.%03d", i)
    }
  }
}

resource "local_file" "stage2" {
  filename = "./stage2/main.tf"
  content = templatefile(
    "./stage2.tmpl",
    { clusters = local.clusters }
  )
}

resource "local_file" "kubeconfig" {
  for_each = local.clusters
  filename = each.value.kubeconfig_path
  content  = module.clusters[each.key].kubeconfig

  provisioner "local-exec" {
    command = <<-EOT
      kubectl ${each.value.dashdash_kubeconfig} get nodes --watch \
      | grep --silent --line-buffered . \
      && kubectl ${each.value.dashdash_kubeconfig} wait node --for=condition=Ready --all --timeout=10m \
      && kubectl ${each.value.dashdash_kubeconfig} get nodes \
      -o 'jsonpath={.items[*].status.addresses[?(@.type=="ExternalIP")].address}' > ${each.value.externalips_path}
      EOT
  }
}
