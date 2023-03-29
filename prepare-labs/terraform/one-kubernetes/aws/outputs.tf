output "cluster_id" {
  value = module.eks.cluster_arn
}

output "has_metrics_server" {
  value = false
}

output "kubeconfig" {
  sensitive = true
  value = yamlencode({
    apiVersion = "v1"
    kind       = "Config"
    clusters = [{
      name = var.cluster_name
      cluster = {
        certificate-authority-data = module.eks.cluster_certificate_authority_data
        server                     = module.eks.cluster_endpoint
      }
    }]
    contexts = [{
      name = var.cluster_name
      context = {
        cluster = var.cluster_name
        user    = var.cluster_name
      }
    }]
    users = [{
      name = var.cluster_name
      user = {
        exec = {
          apiVersion = "client.authentication.k8s.io/v1beta1"
          command    = "aws"
          args       = ["eks", "get-token", "--cluster-name", var.cluster_name]
        }
      }
    }]
    current-context = var.cluster_name
  })
}

data "aws_eks_cluster_auth" "_" {
  name = module.eks.cluster_name
}
