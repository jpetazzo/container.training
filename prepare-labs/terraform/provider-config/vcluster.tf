provider "helm" {
  kubernetes {
    config_path = "~/kubeconfig"
  }
}

provider "kubernetes" {
  config_path = "~/kubeconfig"
}
