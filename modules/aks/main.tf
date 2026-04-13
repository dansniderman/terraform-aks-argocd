locals {
  cluster_dns_prefix            = var.dns_prefix != null ? var.dns_prefix : var.aks_cluster_name
  argocd_application_namespaces = distinct(concat([var.argocd_namespace], var.argocd_application_namespaces))

  argocd_oidc_config = trimspace(<<-EOT
    name: Azure
    issuer: https://login.microsoftonline.com/${var.argocd_entra_tenant_id}/v2.0
    clientID: ${var.argocd_sso_workload_identity_client_id}
    azure:
      useWorkloadIdentity: true
    requestedIDTokenClaims:
      groups:
        essential: true
    requestedScopes:
      - openid
      - profile
      - email
  EOT
  )

  argocd_admin_policy_lines = [
    for object_id in var.argocd_admin_group_object_ids :
    "g, ${object_id}, role:org-admin"
  ]

  argocd_readonly_policy_lines = [
    for object_id in var.argocd_readonly_group_object_ids :
    "g, ${object_id}, role:readonly"
  ]

  argocd_rbac_policy_csv = join("\n", concat([
    "p, role:org-admin, applications, *, */*, allow",
    "p, role:org-admin, clusters, get, *, allow",
    "p, role:org-admin, repositories, get, *, allow",
    "p, role:org-admin, repositories, create, *, allow",
    "p, role:org-admin, repositories, update, *, allow",
    "p, role:org-admin, repositories, delete, *, allow",
    "p, role:readonly, applications, get, */*, allow",
    "p, role:readonly, clusters, get, *, allow",
    "p, role:readonly, repositories, get, *, allow"
  ], local.argocd_admin_policy_lines, local.argocd_readonly_policy_lines))

  argocd_base_configuration_settings = {
    "redis-ha.enabled"                        = "false"
    "configs.params.application\\.namespaces" = join(",", local.argocd_application_namespaces)
  }

  argocd_workload_identity_configuration_settings = var.enable_argocd_workload_identity ? {
    "azure.workloadIdentity.enabled"          = "true"
    "azure.workloadIdentity.clientId"         = var.argocd_workload_identity_client_id
    "azure.workloadIdentity.entraSSOClientId" = var.argocd_sso_workload_identity_client_id
    "configs.cm.oidc\\.config"                = local.argocd_oidc_config
    "configs.cm.url"                          = var.argocd_ui_url
    "configs.rbac.policy\\.default"           = var.argocd_default_policy
    "configs.rbac.policy\\.csv"               = local.argocd_rbac_policy_csv
  } : {}
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = local.cluster_dns_prefix
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.aks_sku_tier

  default_node_pool {
    name                         = "system"
    node_count                   = var.default_node_pool_node_count
    vm_size                      = var.default_node_pool_vm_size
    os_disk_size_gb              = var.default_node_pool_os_disk_size_gb
    only_critical_addons_enabled = false
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
  }

  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  role_based_access_control_enabled = true

  tags = var.tags
}

resource "azapi_resource" "argocd_extension" {
  count = var.enable_argocd ? 1 : 0

  type      = "Microsoft.KubernetesConfiguration/extensions@2023-05-01"
  name      = var.argocd_extension_name
  parent_id = azurerm_kubernetes_cluster.aks.id

  body = {
    properties = {
      extensionType           = "Microsoft.ArgoCD"
      autoUpgradeMinorVersion = true
      releaseTrain            = "Stable"
      scope = {
        cluster = {
          releaseNamespace = var.argocd_namespace
        }
      }
      configurationSettings = merge(
        local.argocd_base_configuration_settings,
        local.argocd_workload_identity_configuration_settings
      )
    }
  }

  response_export_values = ["*"]

  lifecycle {
    precondition {
      condition = (
        !var.enable_argocd ||
        !var.enable_argocd_workload_identity ||
        (
          var.argocd_workload_identity_client_id != null &&
          var.argocd_sso_workload_identity_client_id != null &&
          var.argocd_entra_tenant_id != null &&
          var.argocd_ui_url != null &&
          length(var.argocd_admin_group_object_ids) > 0
        )
      )
      error_message = "When workload identity is enabled for Argo CD, set argocd_workload_identity_client_id, argocd_sso_workload_identity_client_id, argocd_entra_tenant_id, argocd_ui_url, and at least one argocd_admin_group_object_ids value."
    }
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
}
