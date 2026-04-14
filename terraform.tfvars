subscription_id                    = "d5736eb1-f851-4ec3-a2c5-ac8d84d029e2"
location                           = "eastus"
resource_group_name                = "rg-dps-aks-dev"
aks_cluster_name                   = "aks-dps-dev-01"
dns_prefix                         = "aksdpsdev01"
aks_sku_tier                       = "Free"
default_node_pool_vm_size          = "Standard_B2s"
default_node_pool_node_count       = 1
default_node_pool_os_disk_size_gb  = 64
kubernetes_version                 = null
enable_argocd                      = true
argocd_extension_name              = "argocd"
argocd_namespace                   = "argocd"
argocd_application_namespaces      = ["default"]
enable_argocd_workload_identity    = true
argocd_workload_identity_client_id = "00000000-0000-0000-0000-000000000000"
argocd_sso_workload_identity_client_id = "00000000-0000-0000-0000-000000000000"
argocd_entra_tenant_id             = "ed9aa516-5358-4016-a8b2-b6ccb99142d0"
argocd_ui_url                      = "https://argocd-dps.example.com"
argocd_default_policy              = "role:readonly"
argocd_admin_group_object_ids      = ["00000000-0000-0000-0000-000000000000"]
argocd_readonly_group_object_ids   = []

tags = {
  environment = "learning"
  managed_by  = "terraform"
}
