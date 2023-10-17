# main.tf

# Defines the Azure provider block
provider "azurerm" {
  features {}
}

# Creates the Azure Kubernetes Service (AKS) cluster
module "aks_cluster" {
  source = "./aks"
}

# Creates resources for Nginx
module "nginx_resources" {
  source = "./nginx"
}

# Initializes Helm for managing Kubernetes applications
module "helm_init" {
  source = "./helm"
}

# Defines output variables to retrieve important information

# Outputs the Kubernetes configuration for kubectl
output "kube_config" {
  value = module.aks_cluster.kube_config
}

# Outputs the AKS cluster credentials
output "cluster_credentials" {
  value = module.aks_cluster.aks
}

# Outputs the public IP address of the Nginx service
output "nginx_service_public_ip" {
  value = module.nginx_resources.nginx_service_public_ip
}
