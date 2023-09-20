# VNET1WEB.tf

# Define variables here
variable "resource_group_name" {
  description = "Name of the Azure resource group"
  default     = "TerraformRG"
}

variable "location" {
  description = "Azure region for resources"
  default     = "westus3"
}

variable "vnet1_name" {
  description = "Name of the first VNET"
  default     = "VNet1"
}

variable "vnet1_address_space" {
  description = "Address space for the first VNET"
  default     = ["10.0.0.0/16"]
}

variable "vnet1_subnet_name" {
  description = "Name of the subnet in the first VNET"
  default     = "Subnet1"
}

variable "vnet1_subnet_prefix" {
  description = "Address prefix for the subnet in the first VNET"
  default     = "10.0.1.0/24"
}

variable "vnet1_vm_name" {
  description = "Name of the VM in the first VNET"
  default     = "WebVM1"
}

variable "vnet1_vm_size" {
  description = "Size of the VM in the first VNET"
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Admin username for VMs"
  default     = "adminuser"
}

variable "admin_password" {
  description = "Admin password for VMs"
  default     = "P@ssw0rd123!"
}

# Provider configuration
provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "terraform" {
  name     = var.resource_group_name
  location = var.location
}

# Create the first Virtual Network
resource "azurerm_virtual_network" "vnet1" {
  name                = var.vnet1_name
  address_space       = var.vnet1_address_space
  location            = azurerm_resource_group.terraform.location
  resource_group_name = azurerm_resource_group.terraform.name
}

# Create the first subnet
resource "azurerm_subnet" "vnet1_subnet" {
  name                 = var.vnet1_subnet_name
  resource_group_name  = azurerm_resource_group.terraform.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = [var.vnet1_subnet_prefix]
}

# Create a public IP for the first VM
resource "azurerm_public_ip" "vnet1_vm_public_ip" {
  name                = "VNet1_VM_PublicIP"
  location            = azurerm_resource_group.terraform.location
  resource_group_name = azurerm_resource_group.terraform.name
  allocation_method   = "Dynamic"
}

# Create a network interface for the first VM
resource "azurerm_network_interface" "vnet1_vm_nic" {
  name                = "VNet1_VM_NIC"
  location            = azurerm_resource_group.terraform.location
  resource_group_name = azurerm_resource_group.terraform.name

  ip_configuration {
    name                          = "VNet1_VM_NIC_Config"
    subnet_id                     = azurerm_subnet.vnet1_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id           = azurerm_public_ip.vnet1_vm_public_ip.id
  }
}

# Create the first VM running the website
resource "azurerm_windows_virtual_machine" "vnet1_vm" {
  name                = var.vnet1_vm_name
  location            = azurerm_resource_group.terraform.location
  resource_group_name = azurerm_resource_group.terraform.name
  network_interface_ids = [azurerm_network_interface.vnet1_vm_nic.id]

  size       = var.vnet1_vm_size
  admin_username       = var.admin_username
  admin_password       = var.admin_password

  os_disk {
    name                 = "VNet1_OsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  disable_password_authentication = false
}

# Create an external load balancer for the first VM

# Create a load balancer backend pool for the first VM

# Create a load balancer probe for the first VM

# Create a load balancer rule for the first VM

# Output for the public IP address of the first VM
output "public_ip_address_vnet1" {
  value = azurerm_public_ip.vnet1_vm_public_ip.ip_address
}
