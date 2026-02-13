#
# translate-openapi.ps1
#
# Translates and cleans OpenAPI specifications from Google API Gateway/Apigee
# for import into Azure API Management.
#
# Usage: .\translate-openapi.ps1 -InputFile <input> -OutputFile <output>
#

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$InputFile,
    
    [Parameter(Mandatory=$true)]
    [string]$OutputFile,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipValidation
)

# Check if input file exists
if (-not (Test-Path $InputFile)) {
    Write-Error "Input file '$InputFile' not found"
    exit 1
}

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "OpenAPI Translation Tool for APIM" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Input:  $InputFile"
Write-Host "Output: $OutputFile"
Write-Host ""

# Step 1: Validate input with Spectral
Write-Host "[1/4] Validating input OpenAPI spec..." -ForegroundColor Yellow
if (-not $SkipValidation) {
    try {
        $spectralExists = Get-Command spectral -ErrorAction SilentlyContinue
        if ($spectralExists) {
            & spectral lint $InputFile
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Spectral validation found issues. Continuing anyway..."
            }
        } else {
            Write-Warning "Spectral CLI not found. Skipping validation."
            Write-Host "Install with: npm install -g @stoplight/spectral-cli" -ForegroundColor Gray
        }
    } catch {
        Write-Warning "Spectral validation failed: $_"
    }
}

# Step 2: Clean Google-specific extensions
Write-Host "[2/4] Removing Google-specific extensions..." -ForegroundColor Yellow

# TODO: Implement actual transformation logic
# This is a placeholder - actual implementation would:
# - Parse YAML/JSON using PowerShell-Yaml or ConvertFrom-Json
# - Remove x-google-* extensions
# - Normalize paths and operations
# - Add APIM-compatible metadata
# - Handle security schemes

# For now, just copy the file as a starting point
Copy-Item -Path $InputFile -Destination $OutputFile -Force

Write-Host ""
Write-Host "TODO: Implement the following transformations:" -ForegroundColor DarkYellow
Write-Host "  - Remove x-google-backend extensions" -ForegroundColor Gray
Write-Host "  - Remove x-google-management extensions" -ForegroundColor Gray
Write-Host "  - Convert x-google-quota to APIM policy" -ForegroundColor Gray
Write-Host "  - Normalize security schemes" -ForegroundColor Gray
Write-Host "  - Ensure operationId uniqueness" -ForegroundColor Gray
Write-Host ""

# Step 3: Validate output
Write-Host "[3/4] Validating output OpenAPI spec..." -ForegroundColor Yellow
if (-not $SkipValidation) {
    try {
        $spectralExists = Get-Command spectral -ErrorAction SilentlyContinue
        if ($spectralExists) {
            & spectral lint $OutputFile
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Output spec has validation issues."
            }
        }
    } catch {
        Write-Warning "Output validation failed: $_"
    }
}

# Step 4: Summary
Write-Host "[4/4] Translation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Review the output file: $OutputFile" -ForegroundColor Gray
Write-Host "  2. Manually translate any Google-specific policies" -ForegroundColor Gray
Write-Host "  3. Import to APIM using: ..\..\scripts\import-openapi.ps1" -ForegroundColor Gray
Write-Host ""
Write-Warning "This is a helper script. Manual review is required!"
Write-Host "      Refer to: ..\..\docs\migration\google-to-apim.md" -ForegroundColor Gray
Write-Host ""

<#
.SYNOPSIS
    Translates OpenAPI specs from Google API services to Azure APIM format.

.DESCRIPTION
    This script helps migrate OpenAPI specifications from Google Cloud API Gateway
    or Apigee to Azure API Management by cleaning Google-specific extensions and
    preparing the spec for APIM import.
    
    Current implementation is a placeholder. For production use, you need to:
    
    1. Parse YAML/JSON using PowerShell-Yaml module:
       Install-Module powershell-yaml -Force
    
    2. Remove Google-specific extensions:
       - x-google-backend
       - x-google-management
       - x-google-quota
       - x-google-allow
       - x-google-endpoints
    
    3. Transform security schemes:
       - API key locations (query vs header)
       - OAuth flows
       - JWT validation parameters
    
    4. Normalize operation IDs:
       - Ensure uniqueness
       - Follow APIM naming conventions
    
    5. Add APIM-specific extensions if needed

.PARAMETER InputFile
    Path to the input OpenAPI specification file (YAML or JSON)

.PARAMETER OutputFile
    Path to write the cleaned OpenAPI specification

.PARAMETER SkipValidation
    Skip Spectral validation steps

.EXAMPLE
    .\translate-openapi.ps1 -InputFile google-api.yaml -OutputFile apim-api.yaml

.EXAMPLE
    .\translate-openapi.ps1 -InputFile api.json -OutputFile cleaned.json -SkipValidation

.NOTES
    Author: Azure APIM Educational Repository
    
    For full implementation example with PowerShell-Yaml:
    
    # Install module
    Install-Module powershell-yaml -Force
    
    # Load and transform
    $spec = Get-Content $InputFile -Raw | ConvertFrom-Yaml
    
    # Remove Google extensions
    foreach ($path in $spec.paths.Keys) {
        foreach ($operation in $spec.paths[$path].Keys) {
            $spec.paths[$path][$operation].Keys | Where-Object { $_ -like 'x-google-*' } | ForEach-Object {
                $spec.paths[$path][$operation].Remove($_)
            }
        }
    }
    
    # Save cleaned spec
    $spec | ConvertTo-Yaml | Set-Content $OutputFile
    
.LINK
    https://github.com/jonathandhaene/apim-educational
#>
