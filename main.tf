terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.92.0"
    }
  }
}


locals {
  resource_group = "app-grp"
  location       = "westus3"
}

data "template_cloudinit_config" "linuxconfig" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = "packages: ['nginx']"
  }
}

resource "azurerm_resource_group" "app_grp" {
  name     = local.resource_group
  location = local.location
}


resource "azurerm_virtual_network" "app_network" {
  name                = "app-network"
  location            = local.location
  resource_group_name = azurerm_resource_group.app_grp.name
  address_space       = ["10.0.0.0/16"]
  depends_on = [
    azurerm_resource_group.app_grp
  ]
}

resource "azurerm_subnet" "SubnetA" {
  name                 = "SubnetA"
  resource_group_name  = azurerm_resource_group.app_grp.name
  virtual_network_name = azurerm_virtual_network.app_network.name
  address_prefixes     = ["10.0.0.0/24"]
  depends_on = [
    azurerm_virtual_network.app_network
  ]
}

// create interface for  appvm1
resource "azurerm_network_interface" "app_interface1" {
  name                = "app-interface1"
  location            = azurerm_resource_group.app_grp.location
  resource_group_name = azurerm_resource_group.app_grp.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.SubnetA.id
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [
    azurerm_virtual_network.app_network,
    azurerm_subnet.SubnetA
  ]
}


// This is to create Linux VM1

resource "azurerm_linux_virtual_machine" "app_vm1" {
  name                            = "appvm1"
  resource_group_name             = local.resource_group
  location                        = local.location
  size                            = "Standard_B1s"
  admin_username                  = "linuxusr"
  admin_password                  = "Azure@123"
  disable_password_authentication = false
  custom_data                     = data.template_cloudinit_config.linuxconfig.rendered
  network_interface_ids = [
    azurerm_network_interface.app_interface1.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  depends_on = [
    azurerm_network_interface.app_interface1
  ]
}
