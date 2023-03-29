resource "helm_release" "_" {
  name             = "vcluster"
  namespace        = var.cluster_name
  create_namespace = true
  #tags                       = var.common_tags
  repository = "https://charts.loft.sh"
  chart      = "vcluster"
  set {
    name  = "storage.persistence"
    value = "false"
  }
  set {
    name  = "service.type"
    value = "NodePort"
  }
  set {
    name  = "syncer.extraArgs"
    value = "{--tls-san=${local.outer_api_server_host}}"
  }
}
