param(
    [Parameter(Mandatory = $false)]
    [string]$TfvarsPath = "./terraform.tfvars"
)

$ErrorActionPreference = "Stop"

$tfvarsExists = Test-Path -Path $TfvarsPath
if (-not $tfvarsExists) {
    throw "tfvars file not found at path: $TfvarsPath"
}

$placeholderGuid = "00000000-0000-0000-0000-000000000000"
$guidPattern = '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'

$content = Get-Content -Path $TfvarsPath -Raw
$errors = @()
$warnings = @()

function Get-QuotedScalarValue {
    param(
        [string]$Text,
        [string]$Key
    )

    $pattern = '(?m)^\s*' + [regex]::Escape($Key) + '\s*=\s*"([^"]*)"'
    $match = [regex]::Match($Text, $pattern)
    if ($match.Success) {
        return $match.Groups[1].Value.Trim()
    }

    return $null
}

function Get-QuotedListValues {
    param(
        [string]$Text,
        [string]$Key
    )

    $pattern = '(?ms)^\s*' + [regex]::Escape($Key) + '\s*=\s*\[(.*?)\]'
    $match = [regex]::Match($Text, $pattern)
    if (-not $match.Success) {
        return @()
    }

    $inner = $match.Groups[1].Value
    $quotedMatches = [regex]::Matches($inner, '"([^"]+)"')
    $values = @()

    foreach ($m in $quotedMatches) {
        $values += $m.Groups[1].Value.Trim()
    }

    return $values
}

function Validate-GuidValue {
    param(
        [string]$Name,
        [string]$Value,
        [bool]$Required = $true
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        if ($Required) {
            $script:errors += "$Name is missing or empty."
        }
        return
    }

    if ($Value -eq $placeholderGuid) {
        $script:errors += "$Name uses the placeholder GUID value."
        return
    }

    if ($Value -notmatch $guidPattern) {
        $script:errors += "$Name is not a valid GUID: $Value"
    }
}

$requiredGuidKeys = @(
    "argocd_workload_identity_client_id",
    "argocd_sso_workload_identity_client_id",
    "argocd_entra_tenant_id"
)

foreach ($key in $requiredGuidKeys) {
    $value = Get-QuotedScalarValue -Text $content -Key $key
    Validate-GuidValue -Name $key -Value $value -Required $true
}

$uiUrl = Get-QuotedScalarValue -Text $content -Key "argocd_ui_url"
if ([string]::IsNullOrWhiteSpace($uiUrl)) {
    $errors += "argocd_ui_url is missing or empty."
}
elseif ($uiUrl -match "example\.com") {
    $errors += "argocd_ui_url appears to be a placeholder value: $uiUrl"
}

$adminGroups = Get-QuotedListValues -Text $content -Key "argocd_admin_group_object_ids"
if ($adminGroups.Count -lt 1) {
    $errors += "argocd_admin_group_object_ids must contain at least one GUID."
}

foreach ($value in $adminGroups) {
    Validate-GuidValue -Name "argocd_admin_group_object_ids entry" -Value $value -Required $true
}

$readonlyGroups = Get-QuotedListValues -Text $content -Key "argocd_readonly_group_object_ids"
foreach ($value in $readonlyGroups) {
    Validate-GuidValue -Name "argocd_readonly_group_object_ids entry" -Value $value -Required $false
}

if ($errors.Count -gt 0) {
    Write-Host "Workload identity input validation failed:" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host " - $error" -ForegroundColor Red
    }

    if ($warnings.Count -gt 0) {
        Write-Host "Warnings:" -ForegroundColor Yellow
        foreach ($warning in $warnings) {
            Write-Host " - $warning" -ForegroundColor Yellow
        }
    }

    exit 1
}

Write-Host "Workload identity input validation passed for $TfvarsPath" -ForegroundColor Green
