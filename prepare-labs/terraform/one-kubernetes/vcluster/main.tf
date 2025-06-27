resource "helm_release" "_" {
  name             = "vcluster"
  namespace        = var.cluster_name
  create_namespace = true
  repository       = "https://charts.loft.sh"
  chart            = "vcluster"
  version          = "0.19.7"
  values = [
    yamlencode({
      service = {
        type = "NodePort"
      }
      storage = {
        persistence = false
      }
      sync = {
        nodes = {
          enabled      = true
          syncAllNodes = true
        }
      }
      syncer = {
        extraArgs = ["--tls-san=${local.guest_api_server_host}"]
      }
    })
  ]
}
