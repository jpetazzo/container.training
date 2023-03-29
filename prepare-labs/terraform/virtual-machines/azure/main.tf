resource "azurerm_resource_group" "_" {
  name     = var.tag
  location = var.location
}

resource "azurerm_public_ip" "_" {
  for_each            = local.nodes
  name                = each.value.node_name
  location            = azurerm_resource_group._.location
  resource_group_name = azurerm_resource_group._.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "_" {
  for_each            = local.nodes
  name                = each.value.node_name
  location            = azurerm_resource_group._.location
  resource_group_name = azurerm_resource_group._.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet._.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip._[each.key].id
  }
}

resource "azurerm_linux_virtual_machine" "_" {
  for_each            = local.nodes
  name                = each.value.node_name
  resource_group_name = azurerm_resource_group._.name
  location            = azurerm_resource_group._.location
  size                = each.value.node_size
  admin_username      = "ubuntu"
  network_interface_ids = [
    azurerm_network_interface._[each.key].id
  ]

  admin_ssh_key {
    username   = "ubuntu"
    public_key = tls_private_key.ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

# The public IP address only gets allocated when the address actually gets
# attached to the virtual machine. So we need to do this extra indrection
# to retrieve the IP addresses. Otherwise the IP addresses show up as blank.
# See: https://github.com/hashicorp/terraform-provider-azurerm/issues/310#issuecomment-335479735

data "azurerm_public_ip" "_" {
  for_each            = local.nodes
  name                = each.value.node_name
  resource_group_name = azurerm_resource_group._.name
  depends_on          = [azurerm_linux_virtual_machine._]
}

locals {
  ip_addresses = {
    for key, value in local.nodes :
    key => data.azurerm_public_ip._[key].ip_address
  }
}
