output "resource_group_name" {
  description = "Name of the AKS resource group."
  value       = azurerm_resource_group.aks.name
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster."
  value       = module.aks.aks_cluster_name
}

output "aks_cluster_id" {
  description = "Resource ID of the AKS cluster."
  value       = module.aks.aks_cluster_id
}

output "aks_oidc_issuer_url" {
  description = "OIDC issuer URL for the AKS cluster."
  value       = module.aks.aks_oidc_issuer_url
}

output "argocd_extension_id" {
  description = "Resource ID of the Argo CD extension when enabled."
  value       = module.aks.argocd_extension_id
}
