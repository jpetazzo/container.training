resource "azurerm_resource_group" "_" {
  name          = var.prefix
  location = var.location
}

resource "azurerm_public_ip" "_" {
  count               = var.how_many_nodes
  name                = format("%s-%04d", var.prefix, count.index + 1)
  location            = azurerm_resource_group._.location
  resource_group_name = azurerm_resource_group._.name
  allocation_method = "Dynamic"
}

resource "azurerm_network_interface" "_" {
  count               = var.how_many_nodes
  name                = format("%s-%04d", var.prefix, count.index + 1)
  location            = azurerm_resource_group._.location
  resource_group_name = azurerm_resource_group._.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet._.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip._[count.index].id
  }
}

resource "azurerm_linux_virtual_machine" "_" {
  count               = var.how_many_nodes
  name                = format("%s-%04d", var.prefix, count.index + 1)
  resource_group_name = azurerm_resource_group._.name
  location            = azurerm_resource_group._.location
  size                = var.size
  admin_username      = "ubuntu"
  network_interface_ids = [
    azurerm_network_interface._[count.index].id,
  ]

  admin_ssh_key {
    username   = "ubuntu"
    public_key = local.authorized_keys
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS" # FIXME
    version   = "latest"
  }
}

# The public IP address only gets allocated when the address actually gets
# attached to the virtual machine. So we need to do this extra indrection
# to retrieve the IP addresses. Otherwise the IP addresses show up as blank.
# See: https://github.com/hashicorp/terraform-provider-azurerm/issues/310#issuecomment-335479735

data "azurerm_public_ip" "_" {
  count               = var.how_many_nodes
  name                = format("%s-%04d", var.prefix, count.index + 1)
  resource_group_name = azurerm_resource_group._.name
  depends_on = [azurerm_linux_virtual_machine._]
}

output "ip_addresses" {
  value = join("", formatlist("%s\n", data.azurerm_public_ip._.*.ip_address))
}
