resource "azurerm_resource_group" "_" {
  name     = var.cluster_name
  location = var.location
}

resource "azurerm_kubernetes_cluster" "_" {
  name         = var.cluster_name
  location = var.location
  dns_prefix = var.cluster_name
  identity {
   type = "SystemAssigned"
  }
  resource_group_name = azurerm_resource_group._.name
  default_node_pool {
    name       = "x86"
    node_count = var.min_nodes_per_pool
    min_count = var.min_nodes_per_pool
    max_count = var.max_nodes_per_pool
    vm_size    = local.node_size
    enable_auto_scaling = true
  }
}
