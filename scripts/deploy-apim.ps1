# Deploy Azure API Management using Bicep
# Updated for 2026 best practices with enhanced error handling

$ErrorActionPreference = "Stop"

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus",
    
    [Parameter(Mandatory=$false)]
    [string]$ParameterFile = "infra/bicep/params/public-dev.bicepparam",
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf
)

Write-Host "=== Azure API Management Deployment ===" -ForegroundColor Cyan
Write-Host "Resource Group: $ResourceGroup"
Write-Host "Location: $Location"
Write-Host "Parameter File: $ParameterFile"
Write-Host ""

# Check if logged in
try {
    $context = Get-AzContext
    if (!$context) {
        throw "Not logged in"
    }
} catch {
    Write-Host "Not logged in to Azure. Please run: Connect-AzAccount" -ForegroundColor Red
    exit 1
}

# Create resource group if it doesn't exist
$rg = Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue
if (!$rg) {
    Write-Host "Creating resource group $ResourceGroup..." -ForegroundColor Yellow
    New-AzResourceGroup -Name $ResourceGroup -Location $Location
}

# Run what-if or deploy
if ($WhatIf) {
    Write-Host "Running what-if analysis..." -ForegroundColor Yellow
    New-AzResourceGroupDeployment `
        -ResourceGroupName $ResourceGroup `
        -TemplateFile "infra/bicep/main.bicep" `
        -TemplateParameterFile $ParameterFile `
        -WhatIf
} else {
    Write-Host "Deploying APIM..." -ForegroundColor Yellow
    $deployment = New-AzResourceGroupDeployment `
        -ResourceGroupName $ResourceGroup `
        -TemplateFile "infra/bicep/main.bicep" `
        -TemplateParameterFile $ParameterFile `
        -Verbose
    
    Write-Host ""
    Write-Host "=== Deployment Complete ===" -ForegroundColor Green
    Write-Host "Outputs:"
    $deployment.Outputs | Format-Table
}
