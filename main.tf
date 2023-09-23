# Will run Kubernetes with 2 Nodes running NGNIX. They can be accesible from internet since teh type is Load Balancer
#This is main.tf V1.2

# Define variables here
variable "resource_group_name" {
  description = "Name of the Azure resource group"
  default     = "TerraformRG"
}

variable "location" {
  description = "Azure region for resources"
  default     = "westus3"
}

variable "aks_cluster_name" {
  description = "Name of the AKS cluster"
  default     = "my-aks-cluster"
}

variable "aks_node_count" {
  description = "Number of AKS nodes"
  default     = 2
}


variable "aks_node_size" {
  description = "Size of AKS nodes"
  default     = "Standard_B2s"
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

# Create an Azure Kubernetes Service (AKS) cluster
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
}

# Create a Kubernetes Deployment for NGINX
resource "kubernetes_deployment" "nginx" {
  metadata {
    name = "nginx-deployment"
  }


  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }

      spec {
        container {
          image = "nginx:latest"
          name  = "nginx"

          ports {
            container_port = 80
          }
        }
      }
    }
  }
}

# Create a Kubernetes Service of type LoadBalancer to expose NGINX
resource "kubernetes_service" "nginx" {
  metadata {
    name = "nginx-service"
  }

  spec {
    selector = {
      app = "nginx"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}

# Output for the kube_config block to access the AKS cluster
output "kube_config" {
  value = azurerm_kubernetes_cluster.aks.kube_config.0
}

# Output for the AKS cluster's credentials
output "cluster_credentials" {
  value = azurerm_kubernetes_cluster.aks
}

# Output for the public IP address of the NGINX service
output "nginx_service_public_ip" {
  value = kubernetes_service.nginx.status.0.load_balancer_ingress.0.ip
}
