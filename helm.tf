# helm.tf

# Use the helm provider to interact with Helm charts
provider "helm" {
  kubernetes {
    config_path    = module.aks_cluster.kube_config
    config_context = "your-kube-context-name"
  }
}

# Define a Helm release
resource "helm_release" "example" {
  name       = "example"
  repository = "https://example.com/charts"
  chart      = "example-chart"
  version    = "1.2.3"

  # Values to be passed to the Helm chart
  values = [
    {
      key   = "key1",
      value = "value1"
    },
    {
      key   = "key2",
      value = "value2"
    }
  }
}

# Output the Helm release status
output "helm_release_status" {
  value = helm_release.example.status
}
