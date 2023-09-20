# VNET2WEB.tf

# Define variables here
variable "vnet2_name" {
  description = "Name of the second VNET"
  default     = "VNet2"
}

variable "vnet2_address_space" {
  description = "Address space for the second VNET"
  default     = ["10.1.0.0/16"]
}

variable "vnet2_subnet_name" {
  description = "Name of the subnet in the second VNET"
  default     = "Subnet2"
}

variable "vnet2_subnet_prefix" {
  description = "Address prefix for the subnet in the second VNET"
  default     = "10.1.1.0/24"
}

variable "vnet2_vm_name" {
  description = "Name of the VM in the second VNET"
  default     = "WebVM2"
}

variable "vnet2_vm_size" {
  description = "Size of the VM in the second VNET"
  default     = "Standard_B1s"
}

# Provider configuration
provider "azurerm" {
  features {}
}

# Create the second Virtual Network
resource "azurerm_virtual_network" "vnet2" {
  name                = var.vnet2_name
  address_space       = var.vnet2_address_space
  location            = azurerm_resource_group.terraform.location
  resource_group_name = azurerm_resource_group.terraform.name
}

# Create the second subnet
resource "azurerm_subnet" "vnet2_subnet" {
  name                 = var.vnet2_subnet_name
  resource_group_name  = azurerm_resource_group.terraform.name
  virtual_network_name = azurerm_virtual_network.vnet2.name
  address_prefixes     = [var.vnet2_subnet_prefix]
}

# Create a public IP for the second VM
resource "azurerm_public_ip" "vnet2_vm_public_ip" {
  name                = "VNet2_VM_PublicIP"
  location            = azurerm_resource_group.terraform.location
  resource_group_name = azurerm_resource_group.terraform.name
  allocation_method   = "Dynamic"
}

# Create a network interface for the second VM
resource "azurerm_network_interface" "vnet2_vm_nic" {
  name                = "VNet2_VM_NIC"
  location            = azurerm_resource_group.terraform.location
  resource_group_name = azurerm_resource_group.terraform.name

  ip_configuration {
    name                          = "VNet2_VM_NIC_Config"
    subnet_id                     = azurerm_subnet.vnet2_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id           = azurerm_public_ip.vnet2_vm_public_ip.id
  }
}

# Create the second VM running NGINX
resource "azurerm_linux_virtual_machine" "vnet2_vm" {
  name                = var.vnet2_vm_name
  location            = azurerm_resource_group.terraform.location
  resource_group_name = azurerm_resource_group.terraform.name
  network_interface_ids = [azurerm_network_interface.vnet2_vm_nic.id]

  size       = var.vnet2_vm_size
  admin_username       = var.admin_username
  admin_password       = var.admin_password

  os_disk {
    name                 = "VNet2_OsDisk"
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

# Create an external load balancer for the second VM

# Create a load balancer backend pool for the second VM

# Create a load balancer probe for the second VM

# Create a load balancer rule for the second VM

# Create a private DNS zone for the Private Link

# Create a private endpoint for the second VM

# Create a DNS record set in the private DNS zone

# Create a DNS zone link between the VNETs

# Output for the public IP address of the second VM
output "public_ip_address_vnet2" {
  value = azurerm_public_ip.vnet2_vm_public_ip.ip_address
}
