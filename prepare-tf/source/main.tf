module "clusters" {
  source             = "./modules/PROVIDER"
  for_each           = local.clusters
  cluster_name       = each.value.cluster_name
  min_nodes_per_pool = var.min_nodes_per_pool
  max_nodes_per_pool = var.max_nodes_per_pool
  enable_arm_pool    = var.enable_arm_pool
  node_size          = var.node_size
  common_tags        = local.common_tags
  location           = each.value.location
}

locals {
  clusters = {
    for i in range(101, 101 + var.how_many_clusters) :
    i => {
      cluster_name     = format("%s-%03d", local.tag, i)
      kubeconfig_path  = format("./stage2/kubeconfig.%03d", i)
      externalips_path = format("./stage2/externalips.%03d", i)
      flags_path       = format("./stage2/flags.%03d", i)
      location         = local.locations[i % length(local.locations)]
    }
  }
}

resource "local_file" "stage2" {
  filename        = "./stage2/main.tf"
  file_permission = "0644"
  content = templatefile(
    "./stage2.tmpl",
    { clusters = local.clusters }
  )
}

resource "local_file" "flags" {
  for_each        = local.clusters
  filename        = each.value.flags_path
  file_permission = "0600"
  content         = <<-EOT
    has_metrics_server: ${module.clusters[each.key].has_metrics_server}
  EOT
}

resource "local_file" "kubeconfig" {
  for_each        = local.clusters
  filename        = each.value.kubeconfig_path
  file_permission = "0600"
  content         = module.clusters[each.key].kubeconfig
}

resource "local_file" "externalips" {
  for_each        = local.clusters
  filename        = each.value.externalips_path
  file_permission = "0600"
  content         = data.external.externalips[each.key].result.externalips
}

resource "null_resource" "wait_for_nodes" {
  for_each = local.clusters
  provisioner "local-exec" {
    environment = {
      KUBECONFIG = local_file.kubeconfig[each.key].filename
    }
    command = <<-EOT
      set -e
      kubectl get nodes --watch | grep --silent --line-buffered .
      kubectl wait node --for=condition=Ready --all --timeout=10m
      EOT
  }
}

data "external" "externalips" {
  for_each   = local.clusters
  depends_on = [null_resource.wait_for_nodes]
  program = [
    "sh",
    "-c",
    <<-EOT
      set -e
      cat >/dev/null
      export KUBECONFIG=${local_file.kubeconfig[each.key].filename}
      echo -n '{"externalips": "'
      kubectl get nodes \
      -o 'jsonpath={.items[*].status.addresses[?(@.type=="ExternalIP")].address}'
      echo -n '"}'
      EOT
  ]
}
