# database/main.tf

# Define the PostgreSQL Server
resource "azurerm_postgresql_server" "example" {
  name                = "your-postgresql-server-name"
  resource_group_name = azurerm_resource_group.terraform.name
  location            = azurerm_resource_group.terraform.location
  version             = "12"  # Choose the PostgreSQL version you want
  administrator_login          = "your-admin-username"
  administrator_login_password = "your-admin-password"
  ssl_enforcement              = "Enabled"  # Enable SSL for secure connections
  auto_grow_enabled            = "true"
  sku_name                     = "B_Gen5_2"  # Choose an appropriate SKU
}

# Define a PostgreSQL Database
resource "azurerm_postgresql_database" "example" {
  name                = "your-database-name"
  resource_group_name = azurerm_resource_group.terraform.name
  server_name         = azurerm_postgresql_server.example.name
  charset             = "UTF8"  # Choose the appropriate character set
  collation           = "en_US.utf8"  # Choose the appropriate collation
}

# Configure Firewall Rules to Allow Access
resource "azurerm_postgresql_firewall_rule" "example" {
  name                = "all-allowed"
  resource_group_name = azurerm_resource_group.terraform.name
  server_name         = azurerm_postgresql_server.example.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "255.255.255.255"
}

# Define a PostgreSQL User
resource "azurerm_postgresql_server_active_directory_administrator" "example" {
  server_name         = azurerm_postgresql_server.example.name
  resource_group_name = azurerm_resource_group.terraform.name
  login               = "your-postgres-username"
  sid                 = "your-active-directory-sid"
  tenant_id           = "your-azure-active-directory-tenant-id"
}
