# aks/main.tf
resource "azurerm_resource_group" "terraform" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.terraform.location
  resource_group_name = azurerm_resource_group.terraform.name
  dns_prefix          = var.aks_cluster_name

  default_node_pool {
    name       = "default"
    node_count = var.aks_node_count
    vm_size    = var.aks_node_size
  }

  tags = {
    Environment = "Dev"
  }

  # Enable network policy for AKS (optional)
  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
  }

  service_principal {
    client_id     = "your-service-principal-client-id"
    client_secret = "your-service-principal-client-secret"
  }

  addon_profile {
    kube_dashboard {
      enabled = true
    }

    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = "your-log-analytics-workspace-id"
    }

    http_application_routing {
      enabled = true
    }
  }

  role_based_access_control {
    enabled = true
  }

  aad_profile {
    enabled = true
    admin_group_object_ids = ["your-admin-group-object-id"]
  }

  linux_profile {
    admin_username = "adminuser"
    ssh_key {
      key_data = "your-ssh-public-key"
    }
  }

  tags = {
    Environment = "Dev"
  }
}

# Output for AKS cluster configuration
output "aks_cluster_id" {
  value = azurerm_kubernetes_cluster.aks.id
}

output "aks_cluster_fqdn" {
  value = azurerm_kubernetes_cluster.aks.fqdn
}
