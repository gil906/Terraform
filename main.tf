provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "terraform" {
  name     = "TerraformRG"
  location = "westus3"
}

resource "azurerm_virtual_network" "NGNIX_VNET" {
  name                = "NGNIX_VNET"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.terraform.location
  resource_group_name = azurerm_resource_group.terraform.name
}

resource "azurerm_subnet" "ngnix_subnet" {
  name                 = "ngnix_subnet"
  resource_group_name  = azurerm_resource_group.terraform.name
  virtual_network_name = azurerm_virtual_network.NGNIX_VNET.name
  address_prefixes     = ["10.0.1.0/24"]
}

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
    source_address_prefix      = "97.0.0.0/8"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "lb" {
  name                = "LB_PublicIP" # Name for load balancer public IP
  location            = azurerm_resource_group.terraform.location
  resource_group_name = azurerm_resource_group.terraform.name
  allocation_method   = "Dynamic" # or "Static" depending on your preference
}

resource "azurerm_public_ip" "nic" {
  name                = "VM_NICPublicIP" # Name for network interface public IP
  location            = azurerm_resource_group.terraform.location
  resource_group_name = azurerm_resource_group.terraform.name
  allocation_method   = "Dynamic" # or "Static" depending on your preference
}

resource "azurerm_network_interface" "example" {
  name                = "VM_NIC"
  location            = azurerm_resource_group.terraform.location
  resource_group_name = azurerm_resource_group.terraform.name

  ip_configuration {
    name                          = "myNICConfig"
    subnet_id                     = azurerm_subnet.ngnix_subnet.id
    private_ip_address_allocation= "Dynamic"
    public_ip_address_id           = azurerm_public_ip.nic.id
  }
}

resource "azurerm_linux_virtual_machine" "ngnixvm" {
  name                = "NGNIXVM"
  location            = azurerm_resource_group.terraform.location
  resource_group_name   = azurerm_resource_group.terraform.name
  network_interface_ids   =[azurerm_network_interface.example.id]

  size                 ="Standard_B1s"

   admin_username      = var.admin_username
   admin_password      = var.admin_password

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

 disable_password_authentication = false # Password-based authentication is enabled
}
# Create Azure Standard Load Balancer
resource "azurerm_lb" "LB_External" {
    name                ="LB_External"
    location            =azurerm_resource_group.terraform.location
    resource_group_name =azurerm_resource_group.terraform.name
    sku                 ="Basic"

    frontend_ip_configuration {
        name                          ="publicIPAddress"
        public_ip_address_id          = azurerm_public_ip.lb.id
    }
}


# Create LB Backend Pool
resource "azurerm_lb_backend_address_pool" "example" {
    name                ="backendPool"
    loadbalancer_id     =azurerm_lb.LB_External.id
}

# Create LB Probe
resource "azurerm_lb_probe" "HTTPprobe" {
    name                ="httpProbe"
    protocol            ="Tcp"
    port                ="80"
    loadbalancer_id     =azurerm_lb.LB_External.id
}

# Create LB Rule
resource "azurerm_lb_rule" "example" {
    name                           = "http"
    loadbalancer_id                 = azurerm_lb.LB_External.id
    frontend_ip_configuration_name  = "publicIPAddress" # Use the name of the frontend IP configuration here
    backend_address_pool_ids        = [azurerm_lb_backend_address_pool.example.id]
    probe_id                        = azurerm_lb_probe.HTTPprobe.id
  
    protocol = "Tcp"
    frontend_port = 80
    backend_port  = 80
  }


output "public_ip_address" {
  value = azurerm_public_ip.lb.ip_address
}
