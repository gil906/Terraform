# Define your variables here
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

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  default     = "TerraformRG"
}

variable "admin_username" {
  description = "Admin username for the virtual machine"
  default     = "adminuser"
}

variable "admin_password" {
  description = "Admin password for the virtual machine"
  default     = "P@ssw0rd123"
}

# Provider configuration
provider "azurerm" {
  features {}
}

# Module: Network
module "network" {
  source = "./modules/network"
  
  location            = var.location
  address_space       = var.address_space
  subnet_address      = var.subnet_address_prefix
  source_ip_prefix    = var.source_ip_prefix
  resource_group_name = var.resource_group_name
  admin_username       = var.admin_username
  admin_password       = var.admin_password
}

# Module: Load Balancer
module "load_balancer" {
  source = "./modules/load_balancer"
  
  location            = var.location
  resource_group_name = var.resource_group_name
  lb_sku              = "Basic"
}

# Output
output "public_ip_address" {
  value = module.network.lb_public_ip
}
