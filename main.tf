# main.tf

# Define the Azure provider block
provider "azurerm" {
  features {}
}

# Create the Azure Kubernetes Service (AKS) cluster
module "aks_cluster" {
  source = "./aks"
}

# Create resources for Nginx
module "nginx_resources" {
  source = "./nginx"
}

# Initialize Helm for managing Kubernetes applications
module "helm_init" {
  source = "./helm"
}

# Define output variables to retrieve important information

# Output the Kubernetes configuration for kubectl
output "kube_config" {
  value = module.aks_cluster.kube_config
}

# Output the AKS cluster credentials
output "cluster_credentials" {
  value = module.aks_cluster.aks
}

# Output the public IP address of the Nginx service
output "nginx_service_public_ip" {
  value = module.nginx_resources.nginx_service_public_ip
}
