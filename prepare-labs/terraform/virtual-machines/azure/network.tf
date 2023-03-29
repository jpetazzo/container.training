resource "azurerm_virtual_network" "_" {
  name                = var.tag
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group._.location
  resource_group_name = azurerm_resource_group._.name
}

resource "azurerm_subnet" "_" {
  name                 = var.tag
  resource_group_name  = azurerm_resource_group._.name
  virtual_network_name = azurerm_virtual_network._.name
  address_prefixes     = ["10.10.0.0/20"]
}
