param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,

    [Parameter(Mandatory = $true)]
    [string]$ClusterName,

    [Parameter(Mandatory = $true)]
    [string]$Location,

    [Parameter(Mandatory = $false)]
    [string]$IdentityResourceGroup = "rg-dps-identity-dev",

    [Parameter(Mandatory = $false)]
    [string]$WorkloadIdentityName = "mi-dps-argocd-workload",

    [Parameter(Mandatory = $false)]
    [string]$SsoIdentityName = "mi-dps-argocd-sso",

    [Parameter(Mandatory = $false)]
    [string]$ArgocdNamespace = "argocd"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=== Argo CD Workload Identity Setup ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script has two phases:"
Write-Host "  Phase 1 (run now):  Create managed identities"
Write-Host "  Phase 2 (run after terraform apply):  Create federated credentials"
Write-Host ""

# ── Phase 1: Create managed identities ───────────────────────────────────────

Write-Host "--- Phase 1: Managed Identities ---" -ForegroundColor Cyan
Write-Host ""

Write-Host "Creating identity resource group '$IdentityResourceGroup' in '$Location'..."
az group create --name $IdentityResourceGroup --location $Location --output none

Write-Host "Creating workload identity '$WorkloadIdentityName'..."
az identity create --resource-group $IdentityResourceGroup --name $WorkloadIdentityName --output none

Write-Host "Creating SSO identity '$SsoIdentityName'..."
az identity create --resource-group $IdentityResourceGroup --name $SsoIdentityName --output none

$WorkloadClientId = az identity show --resource-group $IdentityResourceGroup --name $WorkloadIdentityName --query clientId --output tsv
$SsoClientId      = az identity show --resource-group $IdentityResourceGroup --name $SsoIdentityName --query clientId --output tsv

Write-Host ""
Write-Host "=== Phase 1 Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Copy these values into terraform.tfvars:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  argocd_workload_identity_client_id     = `"$WorkloadClientId`""
Write-Host "  argocd_sso_workload_identity_client_id = `"$SsoClientId`""
Write-Host ""

# ── Phase 2: Federated credentials (requires cluster to exist) ───────────────

Write-Host "--- Phase 2: Federated Credentials ---" -ForegroundColor Cyan
Write-Host ""

$ClusterExists = az aks show --resource-group $ResourceGroup --name $ClusterName --query name --output tsv 2>$null

if ([string]::IsNullOrWhiteSpace($ClusterExists)) {
    Write-Host "Cluster '$ClusterName' does not exist yet." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "After 'terraform apply' completes, re-run this script with the same parameters"
    Write-Host "to create the federated credentials."
    Write-Host ""
    Write-Host "=== Done (Phase 1 only) ===" -ForegroundColor Green
    exit 0
}

Write-Host "Cluster found. Fetching OIDC issuer URL..."
$OidcIssuer = az aks show --resource-group $ResourceGroup --name $ClusterName --query oidcIssuerProfile.issuerUrl --output tsv

if ([string]::IsNullOrWhiteSpace($OidcIssuer)) {
    Write-Error "OIDC issuer URL is empty. Ensure oidc_issuer_enabled = true was applied to the cluster."
}

Write-Host "OIDC issuer: $OidcIssuer"
Write-Host ""

$federatedCredentials = @(
    @{ Identity = $WorkloadIdentityName; Name = "fic-dps-argocd-repo-server";        Subject = "system:serviceaccount:$($ArgocdNamespace):argocd-repo-server" },
    @{ Identity = $WorkloadIdentityName; Name = "fic-dps-argocd-app-controller";     Subject = "system:serviceaccount:$($ArgocdNamespace):argocd-application-controller" },
    @{ Identity = $SsoIdentityName;      Name = "fic-dps-argocd-server";             Subject = "system:serviceaccount:$($ArgocdNamespace):argocd-server" }
)

foreach ($fc in $federatedCredentials) {
    Write-Host "Creating federated credential '$($fc.Name)' on '$($fc.Identity)'..."
    az identity federated-credential create `
        --resource-group $IdentityResourceGroup `
        --identity-name $fc.Identity `
        --name $fc.Name `
        --issuer $OidcIssuer `
        --subject $fc.Subject `
        --audiences api://AzureADTokenExchange `
        --output none
}

Write-Host ""
Write-Host "=== Phase 2 Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Federated credentials are now wired to the cluster OIDC issuer." -ForegroundColor Green
Write-Host "Argo CD workload identity components can now authenticate to Azure." -ForegroundColor Green
Write-Host ""
Write-Host "Next: Expose the Argo CD UI and verify Entra sign-in." -ForegroundColor Yellow
Write-Host ""
