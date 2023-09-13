variable "location" {
  description = "Azure region for resources"
  default     = "westus3"
}

variable "address_space" {
  description = "Address space for the virtual network"
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefix" {
  description = "Address prefix for the subnet"
  default     = "10.0.1.0/24"
}

variable "source_ip_prefix" {
  description = "Source IP prefix for security group rule"
  default     = "97.0.0.0/8"
}

# Provider configuration
provider "azurerm" {
  features {}
}

# Resource group
resource "azurerm_resource_group" "terraform" {
  name     = "TerraformRG"
  location = var.location
}

# Virtual network
resource "azurerm_virtual_network" "NGINX_VNET" {
  name                = "NGINX_VNET"
  address_space       = var.address_space
  location            = azurerm_resource_group.terraform.location
  resource_group_name = azurerm_resource_group.terraform.name
}

# Subnet
resource "azurerm_subnet" "nginx_subnet" {
  name                 = "nginx_subnet"
  resource_group_name  = azurerm_resource_group.terraform.name
  virtual_network_name = azurerm_virtual_network.NGINX_VNET.name
  address_prefixes     = [var.subnet_address_prefix]
}

# Network security group
resource "azurerm_network_security_group" "NSG_Only_from_Centurylink" {
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

# Public IPs
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

# Network interface
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

# Virtual machine
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

# Load balancer
resource "azurerm_lb" "LB_External" {
  name                = "LB_External"
  location            = azurerm_resource_group.terraform.location
  resource_group_name = azurerm_resource_group.terraform.name
  sku                 = "Basic"

  frontend_ip_configuration {
    name                          = "publicIPAddress"
    public_ip_address_id          = azurerm_public_ip.lb.id
  }
}

# Load balancer backend pool
resource "azurerm_lb_backend_address_pool" "example" {
  name              = "backendPool"
  loadbalancer_id   = azurerm_lb.LB_External.id
}

# Load balancer probe
resource "azurerm_lb_probe" "HTTPprobe" {
  name              = "httpProbe"
  protocol          = "Tcp"
  port              = "80"
  loadbalancer_id   = azurerm_lb.LB_External.id
}

# Load balancer rule
resource "azurerm_lb_rule" "example" {
  name                           = "http"
  loadbalancer_id                 = azurerm_lb.LB_External.id
  frontend_ip_configuration_name  = "publicIPAddress"
  backend_address_pool_ids        = [azurerm_lb_backend_address_pool.example.id]
  probe_id                        = azurerm_lb_probe.HTTPprobe.id
  protocol                        = "Tcp"
  frontend_port                   = 80
  backend_port                    = 80
}

# Output
output "public_ip_address" {
  value = azurerm_public_ip.lb.ip_address
}