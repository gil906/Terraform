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

variable "nginx_image" {
  description = "NGINX container image to use"
  default     = "nginx:latest"
}

variable "enable_https" {
  description = "Enable HTTPS for NGINX"
  default     = true
}

variable "tls_secret_name" {
  description = "Name of the Kubernetes secret for TLS"
  default     = "tls-secret"
}

variable "enable_helm" {
  description = "Enable Helm for deploying applications"
  default     = true
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
          image = var.nginx_image
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

# Optionally, enable HTTPS for NGINX
resource "kubernetes_secret" "tls" {
  count = var.enable_https ? 1 : 0

  metadata {
    name = var.tls_secret_name
  }

  data = {
    "tls.crt" = file("path/to/tls.crt")
    "tls.key" = file("path/to/tls.key")
  }
}

resource "kubernetes_ingress" "nginx" {
  count = var.enable_https ? 1 : 0

  metadata {
    name = "nginx-ingress"
  }

  spec {
    tls {
      secret_name = kubernetes_secret.tls[0].metadata[0].name
    }

    rule {
      host = "your-domain.com"
      http {
        path {
          path = "/"
          backend {
            service_name = kubernetes_service.nginx.metadata[0].name
            service_port = kubernetes_service.nginx.spec[0].port[0].port
          }
        }
      }
    }
  }
}

# Enable Helm for deploying applications
resource "null_resource" "helm_init" {
  count = var.enable_helm ? 1 : 0

  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "helm init --upgrade"
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
  value = kubernetes_service.nginx.status[0].load_balancer_ingress[0].ip
}
