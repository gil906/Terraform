variable "location" {}
variable "address_space" {}
variable "subnet_address" {}
variable "source_ip_prefix" {}
variable "resource_group_name" {}
variable "admin_username" {}
variable "admin_password" {}

resource "azurerm_resource_group" "terraform" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "nginx_vnet" {
  name                = "NGINX_VNET"
  address_space       = var.address_space
  location            = azurerm_resource_group.terraform.location
  resource_group_name = azurerm_resource_group.terraform.name
}

resource "azurerm_subnet" "nginx_subnet" {
  name                 = "nginx_subnet"
  resource_group_name  = azurerm_resource_group.terraform.name
  virtual_network_name = azurerm_virtual_network.nginx_vnet.name
  address_prefixes     = [var.subnet_address]
}

resource "azurerm_network_security_group" "nsg_only_from_centurylink" {
  name                = "NSG_Only_from_Centurylink"
  location            = azurerm_resource_group.terraform.location
  resource_group_name = azurerm_resource_group.terraform.name

  security_rule {
    name                       = "http"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = var.source_ip_prefix
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "lb" {
  name                = "LB_PublicIP"
  location            = azurerm_resource_group.terraform.location
  resource_group_name = azurerm_resource_group.terraform.name
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "nic" {
  name                = "VM_NICPublicIP"
  location            = azurerm_resource_group.terraform.location
  resource_group_name = azurerm_resource_group.terraform.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "example" {
  name                = "VM_NIC"
  location            = azurerm_resource_group.terraform.location
  resource_group_name = azurerm_resource_group.terraform.name

  ip_configuration {
    name                          = "myNICConfig"
    subnet_id                     = azurerm_subnet.nginx_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id           = azurerm_public_ip.nic.id
  }
}

resource "azurerm_linux_virtual_machine" "nginxvm" {
  name                = "NGINXVM"
  location            = azurerm_resource_group.terraform.location
  resource_group_name = azurerm_resource_group.terraform.name
  network_interface_ids = [azurerm_network_interface.example.id]

  size                 = "Standard_B1s"
  admin_username       = var.admin_username
  admin_password       = var.admin_password

  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = filebase64("ngnixinstall.sh")

  disable_password_authentication = false
}

output "lb_public_ip" {
  value = azurerm_public_ip.lb.ip_address
}
