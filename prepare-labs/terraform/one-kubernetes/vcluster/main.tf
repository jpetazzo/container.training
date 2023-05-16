resource "helm_release" "_" {
  name             = "vcluster"
  namespace        = var.cluster_name
  create_namespace = true
  repository       = "https://charts.loft.sh"
  chart            = "vcluster"
  set {
    name  = "service.type"
    value = "NodePort"
  }
  set {
    name  = "storage.persistence"
    value = "false"
  }
  set {
    name  = "sync.nodes.enabled"
    value = "true"
  }
  set {
    name  = "sync.nodes.syncAllNodes"
    value = "true"
  }
  set {
    name  = "syncer.extraArgs"
    value = "{--tls-san=${local.guest_api_server_host}}"
  }
}
