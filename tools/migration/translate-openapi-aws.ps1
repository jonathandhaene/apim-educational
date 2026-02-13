# translate-openapi-aws.ps1
# Translate AWS API Gateway OpenAPI specification to APIM-compatible format
#
# This script removes AWS-specific extensions and prepares the OpenAPI spec
# for import into Azure API Management.
#
# Usage: .\translate-openapi-aws.ps1 -InputFile input.json -OutputFile output.json

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, HelpMessage="Path to input OpenAPI JSON file from AWS")]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [string]$InputFile,
    
    [Parameter(Mandatory=$true, HelpMessage="Path for output APIM-ready OpenAPI JSON file")]
    [string]$OutputFile
)

Write-Host "=== AWS to APIM OpenAPI Translator ===" -ForegroundColor Cyan
Write-Host "Input:  $InputFile"
Write-Host "Output: $OutputFile"
Write-Host ""

try {
    # Load the OpenAPI specification
    Write-Host "Loading OpenAPI specification..." -ForegroundColor Yellow
    $openapi = Get-Content -Path $InputFile -Raw | ConvertFrom-Json
    
    # TODO: Implement comprehensive AWS extension removal
    # This is a stub implementation showing the structure
    
    Write-Host "Removing AWS-specific extensions..." -ForegroundColor Yellow
    
    # Remove root-level AWS extensions
    $awsExtensions = @(
        'x-amazon-apigateway-any-method',
        'x-amazon-apigateway-api-key-source',
        'x-amazon-apigateway-binary-media-types',
        'x-amazon-apigateway-cors',
        'x-amazon-apigateway-gateway-responses',
        'x-amazon-apigateway-policy',
        'x-amazon-apigateway-importexport-version',
        'x-amazon-apigateway-request-validators',
        'x-amazon-apigateway-minimum-compression-size'
    )
    
    foreach ($ext in $awsExtensions) {
        if ($openapi.PSObject.Properties.Name -contains $ext) {
            $openapi.PSObject.Properties.Remove($ext)
            Write-Host "  ✓ Removed root-level: $ext" -ForegroundColor Gray
        }
    }
    
    # Function to recursively remove AWS extensions from nested objects
    function Remove-AwsExtensions {
        param($obj)
        
        if ($null -eq $obj) { return $obj }
        
        if ($obj -is [System.Collections.IDictionary] -or $obj.PSObject -ne $null) {
            $operationExtensions = @(
                'x-amazon-apigateway-integration',
                'x-amazon-apigateway-request-validator',
                'x-amazon-apigateway-authorizer',
                'x-amazon-apigateway-auth'
            )
            
            foreach ($ext in $operationExtensions) {
                if ($obj.PSObject.Properties.Name -contains $ext) {
                    $obj.PSObject.Properties.Remove($ext)
                }
            }
            
            # Recursively process child objects
            foreach ($prop in $obj.PSObject.Properties) {
                if ($prop.Value -is [PSCustomObject] -or $prop.Value -is [System.Collections.IDictionary]) {
                    Remove-AwsExtensions $prop.Value
                } elseif ($prop.Value -is [Array]) {
                    foreach ($item in $prop.Value) {
                        Remove-AwsExtensions $item
                    }
                }
            }
        }
        
        return $obj
    }
    
    # Remove AWS extensions from paths and operations
    if ($openapi.paths) {
        foreach ($pathKey in $openapi.paths.PSObject.Properties.Name) {
            $path = $openapi.paths.$pathKey
            Remove-AwsExtensions $path
        }
    }
    
    # Remove AWS extensions from components
    if ($openapi.components) {
        Remove-AwsExtensions $openapi.components
    }
    
    Write-Host ""
    Write-Host "Saving translated OpenAPI specification..." -ForegroundColor Yellow
    
    # Save the modified OpenAPI spec
    $openapi | ConvertTo-Json -Depth 100 | Set-Content -Path $OutputFile -Encoding UTF8
    
    Write-Host ""
    Write-Host "✓ Translation complete" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Review the output file: $OutputFile"
    Write-Host "  2. Add APIM-specific metadata (servers, security schemes)"
    Write-Host "  3. Validate with Spectral: spectral lint $OutputFile --ruleset .spectral.yaml"
    Write-Host "  4. Import to APIM: .\scripts\import-openapi.ps1"
    Write-Host ""
    Write-Host "TODO: Customize this script to handle:" -ForegroundColor Yellow
    Write-Host "  - Convert stage variables (e.g., `${stageVariables.backendUrl}) to Named Values"
    Write-Host "  - Map AWS integration types to APIM backends"
    Write-Host "  - Preserve any custom x-* extensions you need"
    Write-Host "  - Add appropriate APIM security schemes"
    Write-Host ""
    Write-Host "For more details, see: docs/migration/aws-to-apim.md" -ForegroundColor Cyan
    
} catch {
    Write-Error "Error during translation: $_"
    exit 1
}
