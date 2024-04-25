terraform { 
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.95.0"
    }
  
    }
}

provider "azurerm" {
  features {}

  subscription_id   = "32e56620-61bc-4af1-a985-ce901663f0d2"
  tenant_id         = "b9736dd5-6660-49b8-a580-f277b3069cb3"
  client_id         = "e123ed87-375d-4a8d-9849-7db1e9e1fc8e"
  client_secret     = "xJS8Q~ruxKVrc-BIYxuYmlPqsb9wAMHkCHLFdcb~" 

}


locals {
  resource_group="my_grp"
  location="East US"
}

resource "azurerm_resource_group" "my_grp" {
  name     = local.resource_group
  location = local.location
}

resource "azurerm_virtual_network" "Network-01" {
  name                = "Network-01"
  location            = local.location
  resource_group_name = local.resource_group
  address_space       = ["10.0.0.0/20"]
  depends_on = [ azurerm_resource_group.my_grp ]

}


resource "azurerm_subnet" "Default-01" {
  name                 = "Default-01"
  resource_group_name  = local.resource_group
  virtual_network_name = "Network-01"
  address_prefixes     = ["10.0.0.0/24"]
  depends_on = [ azurerm_virtual_network.Network-01 ]
}


resource "azurerm_network_interface" "app_interface" {
  count =3
  
  name                = format("app-interface%s",(count.index)+1)
  location            = local.location
  resource_group_name = local.resource_group

  ip_configuration {
    name                          = "internal"
    subnet_id                     =  azurerm_subnet.Default-01.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "Linux-VM" {
  count=3
  
  name                = format("Linux-VM%s",(count.index)+1)
  resource_group_name = local.resource_group
  location            = local.location
  size                = "Standard_B1s"
  admin_username      = "davidnovicic"
  admin_password      = "Ninasreca123"
  disable_password_authentication = false 
  
  network_interface_ids = [
    azurerm_network_interface.app_interface[count.index].id,
  ]


  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "8_8"
    version   = "8.8.2023061411"
  }

}

resource "azurerm_bastion_host" "Bastion-host" {
  name                = "Bastion-host"
  location            = local.location
  resource_group_name = local.resource_group

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.AzureBastionSubnet.id
    public_ip_address_id = azurerm_public_ip.Bastion-PIP.id
  }
   depends_on = [ azurerm_subnet.AzureBastionSubnet ]

}


resource "azurerm_subnet" "AzureBastionSubnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = local.resource_group
  virtual_network_name = "Network-01"
  address_prefixes     = ["10.0.1.0/27"]

  depends_on = [ azurerm_virtual_network.Network-01 ]
}
resource "azurerm_public_ip" "Bastion-PIP" {
  name                = "Bastion-PIP"
  location            = local.location
  resource_group_name = local.resource_group
  allocation_method   = "Static"
  sku                 = "Standard"

  depends_on = [ azurerm_resource_group.my_grp ]

}








