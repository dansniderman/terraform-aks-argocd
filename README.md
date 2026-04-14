# Terraform AKS

Starter repository for provisioning an Azure Kubernetes Service (AKS) cluster with Terraform.

## Learning Goals

This repository is intended for learning, so infrastructure decisions should bias toward the lowest practical Azure cost.

- Prefer the AKS `Free` tier unless a feature explicitly requires a paid tier.
- Prefer a single system node pool with the cheapest supported VM size that is practical in the selected region.
- Avoid optional paid services unless they are required for the learning scenario.
- Include Argo CD as part of the cluster setup because GitOps workflows are part of the target learning path.

## Naming Convention

Because this is a shared lab subscription and shared Entra tenant, use `dps` in names that are shared or externally exposed.

- Required: resource group names should start with `rg-dps`.
- Recommended: include `dps` in AKS cluster name and DNS prefix.
- Required for exposed endpoints: include `dps` in URL-facing hostnames such as Argo CD UI URLs.
- Optional: cluster-local names that are not externally exposed can omit `dps`.

## Layout

- `.github/copilot-instructions.md`: workspace-wide Copilot guidance for this repo
- `.github/prompts/`: reusable prompt files available from Copilot Chat with `/`
- `scripts/bootstrap-azure-prereqs.ps1`: local prerequisite bootstrap for Azure CLI, providers, and extensions
- `scripts/setup-workload-identity.ps1`: creates managed identities and federated credentials for Argo CD workload identity
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

Run [scripts/setup-workload-identity.ps1](scripts/setup-workload-identity.ps1) to create the managed identities and (after cluster creation) the federated credentials.

The script runs in two phases automatically:
- **Phase 1** (before `terraform apply`): creates the managed identities and prints the client IDs to copy into `terraform.tfvars`.
- **Phase 2** (after `terraform apply`): re-run the same script to create federated credentials using the cluster OIDC issuer. If the cluster does not exist yet it skips phase 2 and tells you to re-run.

No secrets are created. Workload identity uses OIDC tokens rather than passwords or client secrets.

```powershell
./scripts/setup-workload-identity.ps1 `
  -ResourceGroup "rg-dps-aks-dev" `
  -ClusterName   "aks-dps-dev-01" `
  -Location      "eastus"
```

The script will print the values to paste into `terraform.tfvars`.

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

## Start Here (First Run)

Use this sequence to begin right away in your shared lab subscription:

1. Run prerequisite bootstrap:

```powershell
./scripts/bootstrap-azure-prereqs.ps1
```

2. Create your tfvars from the example:

```powershell
Copy-Item ./terraform.tfvars.example ./terraform.tfvars
```

3. Edit `terraform.tfvars` and set real values for:
	- `subscription_id`
	- `resource_group_name` (must start with `rg-dps`)
	- `aks_cluster_name` (include `dps`)
	- `dns_prefix` (include `dps`)
	- `argocd_entra_tenant_id`
	- `argocd_ui_url` (include `dps` in hostname)
	- `argocd_admin_group_object_ids`

4. Run the workload identity setup script (Phase 1) to create managed identities and get the client IDs:

```powershell
./scripts/setup-workload-identity.ps1 `
  -ResourceGroup "rg-dps-aks-dev" `
  -ClusterName   "aks-dps-dev-01" `
  -Location      "eastus"
```

Copy the printed `argocd_workload_identity_client_id` and `argocd_sso_workload_identity_client_id` values into `terraform.tfvars`.

5. Validate workload identity inputs:

```powershell
./scripts/validate-workload-identity-inputs.ps1 -TfvarsPath ./terraform.tfvars
```

5. Deploy:

```powershell
terraform init
terraform plan
terraform apply
```

## Updated Next Steps

1. Re-run `./scripts/setup-workload-identity.ps1` (Phase 2) to create federated credentials now that the cluster exists.
2. Expose the Argo CD UI endpoint and verify Entra sign-in and RBAC behavior for admin and optional readonly groups.
3. Add role assignments for any private registries or Azure services Argo CD needs to reach (for example ACR pull).
4. Add environment-specific hardening (network controls, tighter RBAC policy, and tag standards) once the learning baseline is working.
