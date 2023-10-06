# outputs.tf
output "kube_config" {
  value = module.aks_cluster.kube_config
}

output "cluster_credentials" {
  value = module.aks_cluster.aks
}

output "nginx_service_public_ip" {
  value = module.nginx_resources.nginx_service_public_ip
}
