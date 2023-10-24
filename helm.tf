# main.tf

variable "chart_name" {
  description = "Name of the Helm chart"
  type        = string
  default     = "example-chart"
}

variable "chart_version" {
  description = "Version of the Helm chart"
  type        = string
  default     = "1.2.3"
}

variable "chart_repository" {
  description = "URL of the Helm chart repository"
  type        = string
  default     = "https://example.com/charts"
}

variable "chart_values" {
  description = "Values to be passed to the Helm chart"
  type        = map(string)
  default     = {
    key1 = "value1"
    key2 = "value2"
  }
}

provider "helm" {
  kubernetes {
    config_path    = module.aks_cluster.kube_config
    config_context = "your-kube-context-name"
  }
}

# Define a Helm release
resource "helm_release" "example" {
  name       = "example"
  repository = var.chart_repository
  chart      = var.chart_name
  version    = var.chart_version

  values = [
    for key, value in var.chart_values : {
      key   = key
      value = value
    }
  ]
}

# Output the Helm release status
output "helm_release_status" {
  value = helm_release.example.status
}

# Output more information
output "helm_release_name" {
  value = helm_release.example.name
}

output "helm_release_namespace" {
  value = helm_release.example.namespace
}

output "helm_release_info" {
  value = helm_release.example
}
