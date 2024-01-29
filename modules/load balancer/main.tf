variable "location" {}
variable "resource_group_name" {}
variable "lb_sku" {}

resource "azurerm_lb" "lb_external" {
  name                = "LB_External"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.lb_sku

  frontend_ip_configuration {
    name                          = "publicIPAddress"
    public_ip_address_id          = azurerm_public_ip.lb.id
  }
}

resource "azurerm_lb_backend_address_pool" "example" {
  name              = "backendPool"
  loadbalancer_id   = azurerm_lb.lb_external.id
}

resource "azurerm_lb_probe" "http_probe" {
  name              = "httpProbe"
  protocol          = "Tcp"
  port              = "80"
  loadbalancer_id   = azurerm_lb.lb_external.id
}

resource "azurerm_lb_rule" "http" {
  name                           = "http"
  loadbalancer_id                 = azurerm_lb.lb_external.id
  frontend_ip_configuration_name  = "publicIPAddress"
  backend_address_pool_ids        = [azurerm_lb_backend_address_pool.example.id]
  probe_id                        = azurerm_lb_probe.http_probe.id
  protocol                        = "Tcp"
  frontend_port                   = 80
  backend_port                    = 80
}

output "lb_id" {
  value = azurerm_lb.lb_external.id
}
