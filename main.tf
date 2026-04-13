resource "azurerm_resource_group" "aks" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

module "aks" {
  source = "./modules/aks"

  resource_group_name                    = azurerm_resource_group.aks.name
  location                               = azurerm_resource_group.aks.location
  aks_cluster_name                       = var.aks_cluster_name
  dns_prefix                             = var.dns_prefix
  aks_sku_tier                           = var.aks_sku_tier
  default_node_pool_vm_size              = var.default_node_pool_vm_size
  default_node_pool_node_count           = var.default_node_pool_node_count
  default_node_pool_os_disk_size_gb      = var.default_node_pool_os_disk_size_gb
  kubernetes_version                     = var.kubernetes_version
  enable_argocd                          = var.enable_argocd
  argocd_extension_name                  = var.argocd_extension_name
  argocd_namespace                       = var.argocd_namespace
  argocd_application_namespaces          = var.argocd_application_namespaces
  enable_argocd_workload_identity        = var.enable_argocd_workload_identity
  argocd_workload_identity_client_id     = var.argocd_workload_identity_client_id
  argocd_sso_workload_identity_client_id = var.argocd_sso_workload_identity_client_id
  argocd_entra_tenant_id                 = var.argocd_entra_tenant_id
  argocd_ui_url                          = var.argocd_ui_url
  argocd_default_policy                  = var.argocd_default_policy
  argocd_admin_group_object_ids          = var.argocd_admin_group_object_ids
  argocd_readonly_group_object_ids       = var.argocd_readonly_group_object_ids
  tags                                   = var.tags
}
