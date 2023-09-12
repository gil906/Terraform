#Bard V1 + manual
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "TerraformRG"
  location = "westus3"
}

resource "azurerm_virtual_network" "example" {
  name                = "myVNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "example" {
  name                = "myNSG"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

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
  name                = "myPublicIP" # Name for load balancer public IP
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Dynamic" # or "Static" depending on your preference
}

resource "azurerm_public_ip" "nic" {
  name                = "myNICPublicIP" # Name for network interface public IP
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Dynamic" # or "Static" depending on your preference
}

resource "azurerm_network_interface" "example" {
  name                = "myNIC"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "myNICConfig"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation= "Dynamic"
    public_ip_address_id           = azurerm_public_ip.nic.id
  }
}

resource "azurerm_linux_virtual_machine" "example" {
  name                = "myVM"
  location            = azurerm_resource_group.example.location
  resource_group_name   = azurerm_resource_group.example.name
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
resource "azurerm_lb" "example" {
    name                ="myLB"
    location            ="${azurerm_resource_group.example.location}"
    resource_group_name ="${azurerm_resource_group.example.name}"
    sku                 ="Basic"

    frontend_ip_configuration {
        name                          ="publicIPAddress"
        public_ip_address_id          ="${azurerm_public_ip.lb.id}"
    }
}

# Create LB Backend Pool
resource "azurerm_lb_backend_address_pool" "example" {
    name                ="backendPool"
    loadbalancer_id     ="${azurerm_lb.example.id}"
}
# Create LB Probe
resource "azurerm_lb_probe" "example" {
    name                ="httpProbe"
    protocol            ="Tcp"
    port                ="80"
    loadbalancer_id     ="${azurerm_lb.example.id}"
}

# Create LB Rule
resource "azurerm_lb_rule" "example" {
    name                           = "http"
    loadbalancer_id                 = azurerm_lb.example.id
    frontend_ip_configuration_name  = azurerm_lb.example.frontend_ip_configuration[0].name
    backend_address_pool_ids         = [azurerm_lb_backend_address_pool.example.id]
    probe_id                        = azurerm_lb_probe.example.id
  
    protocol = "Tcp"
    frontend_port = 80
    backend_port  = 80
  }


output "public_ip_address" {
  value = azurerm_public_ip.lb.ip_address
}
