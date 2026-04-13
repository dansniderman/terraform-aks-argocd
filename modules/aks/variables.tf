variable "resource_group_name" {
  description = "Name of the resource group that will contain AKS resources."
  type        = string
}

variable "location" {
  description = "Azure region for deployed resources."
  type        = string
}

variable "aks_cluster_name" {
  description = "Name of the AKS cluster."
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS API server. Defaults to the cluster name when null."
  type        = string
  default     = null
}

variable "aks_sku_tier" {
  description = "AKS pricing tier. Use Free for low-cost learning environments unless a paid tier is required."
  type        = string
  default     = "Free"
}

variable "default_node_pool_vm_size" {
  description = "VM size for the default AKS system node pool. Keep this on a low-cost size for learning environments."
  type        = string
  default     = "Standard_B2s"
}

variable "default_node_pool_node_count" {
  description = "Node count for the default AKS system node pool. One node is the lowest practical default for learning."
  type        = number
  default     = 1
}

variable "default_node_pool_os_disk_size_gb" {
  description = "OS disk size in GB for the default AKS system node pool."
  type        = number
  default     = 64
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version. Leave null to let Azure choose the default supported version."
  type        = string
  default     = null
}

variable "enable_argocd" {
  description = "Whether the environment should include Argo CD for GitOps learning scenarios."
  type        = bool
  default     = true
}

variable "argocd_extension_name" {
  description = "Name of the Azure Argo CD cluster extension."
  type        = string
  default     = "argocd"
}

variable "argocd_namespace" {
  description = "Namespace where Argo CD will be installed when enabled."
  type        = string
  default     = "argocd"
}

variable "argocd_application_namespaces" {
  description = "Namespaces Argo CD applications are allowed to target in the learning environment."
  type        = list(string)
  default     = ["default"]
}

variable "enable_argocd_workload_identity" {
  description = "Whether to configure Argo CD extension with workload identity and Microsoft Entra ID SSO settings."
  type        = bool
  default     = true
}

variable "argocd_workload_identity_client_id" {
  description = "Client ID of the managed identity used by Argo CD workload identity components."
  type        = string
  default     = null
}

variable "argocd_sso_workload_identity_client_id" {
  description = "Client ID of the managed identity used for Argo CD UI SSO with Microsoft Entra ID."
  type        = string
  default     = null
}

variable "argocd_entra_tenant_id" {
  description = "Microsoft Entra tenant ID used in the Argo CD OIDC configuration."
  type        = string
  default     = null
}

variable "argocd_ui_url" {
  description = "Public URL for the Argo CD UI used in OIDC callback and Argo CD config."
  type        = string
  default     = null
}

variable "argocd_default_policy" {
  description = "Default Argo CD RBAC policy when workload identity mode is enabled."
  type        = string
  default     = "role:readonly"
}

variable "argocd_admin_group_object_ids" {
  description = "Microsoft Entra group object IDs that should receive org-admin rights in Argo CD RBAC policy."
  type        = list(string)
  default     = []
}

variable "argocd_readonly_group_object_ids" {
  description = "Optional Microsoft Entra group object IDs that should receive readonly rights in Argo CD RBAC policy."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to created Azure resources."
  type        = map(string)
  default     = {}
}
