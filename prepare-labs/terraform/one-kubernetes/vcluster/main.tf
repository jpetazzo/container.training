resource "helm_release" "_" {
  name             = "vcluster"
  namespace        = var.cluster_name
  create_namespace = true
  repository       = "https://charts.loft.sh"
  chart            = "vcluster"
  version          = "0.27.1"
  values = [
    yamlencode({
      controlPlane = {
        proxy = {
          extraSANs = [ local.guest_api_server_host ]
        }
        service = {
          spec = {
            type = "NodePort"
          }
        }
        statefulSet = {
          persistence = {
            volumeClaim = {
              enabled = true
            }
          }
        }
      }
      sync = {
        fromHost = {
          nodes = {
            enabled = true
            selector = {
              all = true
            }
          }
        }
      }
    })
  ]
}
