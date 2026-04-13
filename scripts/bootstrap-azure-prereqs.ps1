param(
    [switch]$InstallKubectl = $true
)

$ErrorActionPreference = "Stop"

Write-Host "Checking Azure CLI version..."
az version

Write-Host "Registering required Azure resource providers..."
az provider register --namespace Microsoft.Kubernetes
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.KubernetesConfiguration

Write-Host "Installing or updating required Azure CLI extensions..."
az extension add --name k8s-configuration --upgrade
az extension add --name k8s-extension --upgrade

if ($InstallKubectl) {
    Write-Host "Installing kubectl through Azure CLI..."
    az aks install-cli
}

Write-Host "Current provider registration state:"
az provider show --namespace Microsoft.KubernetesConfiguration --query "{namespace:namespace,state:registrationState}" --output table
