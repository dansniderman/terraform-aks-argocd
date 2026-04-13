# Terraform AKS

Starter repository for provisioning an Azure Kubernetes Service (AKS) cluster with Terraform.

## Learning Goals

This repository is intended for learning, so infrastructure decisions should bias toward the lowest practical Azure cost.

- Prefer the AKS `Free` tier unless a feature explicitly requires a paid tier.
- Prefer a single system node pool with the cheapest supported VM size that is practical in the selected region.
- Avoid optional paid services unless they are required for the learning scenario.
- Include Argo CD as part of the cluster setup because GitOps workflows are part of the target learning path.

## Layout

- `.github/copilot-instructions.md`: workspace-wide Copilot guidance for this repo
- `.github/prompts/`: reusable prompt files available from Copilot Chat with `/`
- `scripts/bootstrap-azure-prereqs.ps1`: local prerequisite bootstrap for Azure CLI, providers, and extensions
- `scripts/validate-workload-identity-inputs.ps1`: pre-apply validator for workload identity placeholders in tfvars
- `modules/aks/`: reusable AKS module for cluster and Argo CD extension
  - `main.tf`: AKS cluster and extension resources
  - `variables.tf`: module input variables
  - `outputs.tf`: cluster, OIDC issuer, and extension outputs
  - `versions.tf`: module provider requirements
- `versions.tf`: root Terraform version and provider constraints
- `providers.tf`: root provider configuration
- `main.tf`: root composition (resource group + AKS module)
- `variables.tf`: root input variable declarations
- `outputs.tf`: root outputs (pass-through from module)
- `terraform.tfvars.example`: example values to copy into a real tfvars file later

## Using Copilot Prompts

Open Copilot Chat in VS Code and type `/` to find the saved workspace prompts in `.github/prompts/`.

## Microsoft Tutorial Alignment

This repository is aligned to the Microsoft guidance for GitOps with Argo CD on AKS:

- The AKS cluster is created with managed identity.
- The cluster defaults toward a low-cost learning footprint.
- Argo CD is installed through the `Microsoft.ArgoCD` cluster extension pattern.
- The Argo CD extension is configured in workload identity mode by default for Microsoft Entra authentication.
- Redis HA is disabled so Argo CD can run on a single-node learning cluster.

## Prerequisites

Before applying Terraform, make sure the Azure prerequisites from the Microsoft tutorial are in place:

1. Azure CLI is installed and up to date.
2. `kubectl` is installed.
3. Azure resource providers are registered:
	- `Microsoft.ContainerService`
	- `Microsoft.Kubernetes`
	- `Microsoft.KubernetesConfiguration`
4. Azure CLI extensions are installed or updated:
	- `k8s-configuration`
	- `k8s-extension`
5. Workload identity inputs are prepared:
	- One managed identity client ID for Argo CD workload identity (`argocd_workload_identity_client_id`)
	- One managed identity client ID for Argo CD UI Entra SSO (`argocd_sso_workload_identity_client_id`)
	- Your Microsoft Entra tenant ID, at least one admin group object ID, and optional readonly group object IDs
	- A reachable Argo CD UI URL for OIDC callback

For Windows PowerShell, you can run [scripts/bootstrap-azure-prereqs.ps1](scripts/bootstrap-azure-prereqs.ps1) to perform the prerequisite setup commands from the tutorial.

## Create Workload Identity Prereqs

The following Azure CLI sequence creates two managed identities, fetches the AKS OIDC issuer, and creates federated credentials for Argo CD service accounts.

```powershell
# Set environment values
$RESOURCE_GROUP = "rg-dps-aks-dev"
$CLUSTER_NAME = "aks-dev-01"
$LOCATION = "eastus"
$WI_RESOURCE_GROUP = "rg-dps-identity-dev"
$WORKLOAD_MI_NAME = "mi-argocd-workload"
$SSO_MI_NAME = "mi-argocd-sso"

# Create a resource group for identities (or reuse an existing one)
az group create --name $WI_RESOURCE_GROUP --location $LOCATION

# Create managed identities
az identity create --resource-group $WI_RESOURCE_GROUP --name $WORKLOAD_MI_NAME
az identity create --resource-group $WI_RESOURCE_GROUP --name $SSO_MI_NAME

# Capture client IDs
$WORKLOAD_CLIENT_ID = az identity show --resource-group $WI_RESOURCE_GROUP --name $WORKLOAD_MI_NAME --query clientId --output tsv
$SSO_CLIENT_ID = az identity show --resource-group $WI_RESOURCE_GROUP --name $SSO_MI_NAME --query clientId --output tsv

# Get AKS OIDC issuer URL
$OIDC_ISSUER = az aks show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --query oidcIssuerProfile.issuerUrl --output tsv

# Create federated credentials for Argo CD service accounts
az identity federated-credential create --resource-group $WI_RESOURCE_GROUP --identity-name $WORKLOAD_MI_NAME --name fic-argocd-repo-server --issuer $OIDC_ISSUER --subject system:serviceaccount:argocd:argocd-repo-server --audiences api://AzureADTokenExchange
az identity federated-credential create --resource-group $WI_RESOURCE_GROUP --identity-name $WORKLOAD_MI_NAME --name fic-argocd-app-controller --issuer $OIDC_ISSUER --subject system:serviceaccount:argocd:argocd-application-controller --audiences api://AzureADTokenExchange
az identity federated-credential create --resource-group $WI_RESOURCE_GROUP --identity-name $SSO_MI_NAME --name fic-argocd-server --issuer $OIDC_ISSUER --subject system:serviceaccount:argocd:argocd-server --audiences api://AzureADTokenExchange

# Example role assignment for pulling from ACR
# Replace <acr-resource-id> with your ACR resource ID
az role assignment create --assignee-object-id $(az identity show --resource-group $WI_RESOURCE_GROUP --name $WORKLOAD_MI_NAME --query principalId -o tsv) --role AcrPull --scope <acr-resource-id>
```

Populate these outputs into your tfvars values:

- `argocd_workload_identity_client_id = $WORKLOAD_CLIENT_ID`
- `argocd_sso_workload_identity_client_id = $SSO_CLIENT_ID`

## What Terraform Creates

- A resource group for the learning environment.
- An AKS cluster using system-assigned managed identity.
- A single default system node pool with low-cost defaults.
- OIDC issuer and workload identity support on the cluster.
- An `argocd` cluster extension using `Microsoft.ArgoCD` with workload identity and Entra OIDC configuration.
- Redis HA disabled for a single-node learning cluster.

## Cost Notes

- AKS uses the `Free` tier by default.
- The node pool defaults to one `Standard_B2s` node, which is a cheapest-practical starting point for learning.
- The load balancer SKU remains `standard`, which is the current AKS baseline and may still incur cost.
- Exposing the Argo CD UI with a public LoadBalancer can add cost and should only be done when needed.

## Workload Identity Notes

- Workload identity setup for external Azure resource access (for example ACR pull) still requires federated identity credential setup and role assignments on target resources.
- This repository configures the Argo CD extension settings for workload identity, but identity and role wiring is environment-specific and should be completed before production use.
- `argocd_readonly_group_object_ids` can be used to map additional Entra groups to readonly access without making them org admins.

## Apply Flow

1. Run the Azure prerequisite bootstrap script or perform the equivalent Azure CLI commands manually.
2. Copy `terraform.tfvars.example` to a real tfvars file and set your subscription, naming, and workload identity values.
3. Run `./scripts/validate-workload-identity-inputs.ps1 -TfvarsPath ./terraform.tfvars`.
4. Run `terraform init`.
5. Run `terraform plan`.
6. Run `terraform apply`.

After apply, use the cluster outputs to connect with `kubectl`. If you want to expose the Argo CD UI exactly like the tutorial, run a `kubectl expose service` command against the `argocd-server` service after the extension is installed.

## Next Steps

1. Decide whether to keep the root-module layout or extract the AKS resources into `modules/aks`.
2. Add a sample Argo CD `Application` manifest for the first GitOps deployment.
3. Add environment-specific federated credentials and role assignments for private registries or other Azure dependencies.
