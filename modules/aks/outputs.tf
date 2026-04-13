output "aks_cluster_name" {
  description = "Name of the AKS cluster."
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_cluster_id" {
  description = "Resource ID of the AKS cluster."
  value       = azurerm_kubernetes_cluster.aks.id
}

output "aks_oidc_issuer_url" {
  description = "OIDC issuer URL for the AKS cluster."
  value       = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}

output "argocd_extension_id" {
  description = "Resource ID of the Argo CD extension when enabled."
  value       = try(azapi_resource.argocd_extension[0].id, null)
}
