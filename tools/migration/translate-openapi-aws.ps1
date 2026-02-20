#
# translate-openapi-aws.ps1
#
# Translates and cleans OpenAPI specifications exported from AWS API Gateway
# for import into Azure API Management.
#
# Features:
#   - Removes AWS-specific extensions (x-amazon-*)
#   - Converts OpenAPI 2.0 (Swagger) specifications to OpenAPI 3.0
#   - Automatically generates operationId for operations that lack one
#   - Validates APIM-specific requirements (title, version, server URLs, security)
#
# Usage: .\translate-openapi-aws.ps1 -InputFile <input> -OutputFile <output>
#
# Prerequisites:
#   - Python 3 with PyYAML (pip install pyyaml)
#   - Spectral CLI (optional): npm install -g @stoplight/spectral-cli
#
# See also:
#   - ..\..\docs\migration\aws-to-apim.md   (full migration guide)
#   - openapi_utils.py                      (core processing library)
#

$ErrorActionPreference = "Stop"

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

# Resolve the directory of this script so we can locate openapi_utils.py
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "OpenAPI Translation Tool for APIM (AWS)" -ForegroundColor Cyan
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

# Step 2: Run openapi_utils.py (removes AWS extensions, converts Swagger→OAS3,
#         generates missing operationIds, validates APIM requirements)
Write-Host "[2/4] Processing spec with openapi_utils.py (source: aws)..." -ForegroundColor Yellow
$pythonCmd = Get-Command python3 -ErrorAction SilentlyContinue
if (-not $pythonCmd) {
    $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
}

if ($pythonCmd) {
    $utilsScript = Join-Path $ScriptDir "openapi_utils.py"
    & $pythonCmd.Name $utilsScript $InputFile $OutputFile --source aws
    if ($LASTEXITCODE -ne 0) {
        Write-Error "openapi_utils.py processing failed."
        exit 1
    }
} else {
    Write-Warning "Python 3 not found. Falling back to file copy."
    Write-Host "Install Python 3 to enable automatic translation features:" -ForegroundColor Gray
    Write-Host "  - Swagger 2.0 -> OpenAPI 3.0 conversion" -ForegroundColor Gray
    Write-Host "  - Automatic operationId generation" -ForegroundColor Gray
    Write-Host "  - APIM requirement validation" -ForegroundColor Gray
    Copy-Item -Path $InputFile -Destination $OutputFile -Force
}

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
Write-Host "  2. Manually translate any AWS-specific policies:" -ForegroundColor Gray
Write-Host "     - Lambda authorizers  -> validate-jwt or custom policies" -ForegroundColor Gray
Write-Host "     - Cognito User Pools  -> validate-jwt (OpenID Connect)" -ForegroundColor Gray
Write-Host "     - Usage plans/API keys -> APIM subscriptions" -ForegroundColor Gray
Write-Host "     - Stage variables      -> APIM Named Values" -ForegroundColor Gray
Write-Host "  3. Import to APIM using: ..\..\scripts\import-openapi.ps1" -ForegroundColor Gray
Write-Host ""
Write-Warning "This is a helper script. Manual review is required!"
Write-Host "      Refer to: ..\..\docs\migration\aws-to-apim.md" -ForegroundColor Gray
Write-Host ""

<#
.SYNOPSIS
    Translates OpenAPI specs exported from AWS API Gateway to Azure APIM format.

.DESCRIPTION
    This script helps migrate OpenAPI specifications from AWS API Gateway to Azure
    API Management by:
      - Removing AWS-specific extensions (x-amazon-*)
      - Converting Swagger 2.0 specifications to OpenAPI 3.0 (via openapi_utils.py)
      - Automatically generating operationId for operations that lack one
      - Validating APIM-specific requirements (title, version, server URLs, security)

    Requires Python 3 with PyYAML installed:
        pip install pyyaml

    Export your REST API from AWS first:
        aws apigateway get-export `
          --rest-api-id <api-id> --stage-name prod `
          --export-type oas30 --accepts application/yaml `
          > aws-api-export.yaml

.PARAMETER InputFile
    Path to the input OpenAPI specification file exported from AWS (YAML or JSON)

.PARAMETER OutputFile
    Path to write the cleaned OpenAPI specification ready for APIM import

.PARAMETER SkipValidation
    Skip Spectral linting steps

.EXAMPLE
    .\translate-openapi-aws.ps1 -InputFile aws-api-export.yaml -OutputFile apim-api.yaml

.EXAMPLE
    .\translate-openapi-aws.ps1 -InputFile api.json -OutputFile cleaned.json -SkipValidation

.NOTES
    Author: Azure APIM Educational Repository

.LINK
    https://github.com/jonathandhaene/apim-educational
#>
