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

# AKS Node Configuration
variable "aks_node_count" {
  description = "Number of AKS nodes"
  default     = 2
}

variable "aks_node_size" {
  description = "Size of AKS nodes"
  default     = "Standard_B2s"
}

# NGINX Configuration
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

# Helm Configuration
variable "enable_helm" {
  description = "Enable Helm for deploying applications"
  default     = true
}
