# Import OpenAPI specification into Azure API Management
param(
    [string]$ResourceGroup = $env:RESOURCE_GROUP ?? "rg-apim-dev",
    [string]$ApimName = $env:APIM_NAME ?? "apim-dev",
    [string]$ApiId = $env:API_ID ?? "sample-api",
    [string]$ApiPath = $env:API_PATH ?? "sample",
    [string]$OpenApiFile = $env:OPENAPI_FILE ?? "src/functions-sample/openapi.json"
)

Write-Host "=== Importing OpenAPI to APIM ===" -ForegroundColor Cyan
Write-Host "APIM: $ApimName"
Write-Host "API ID: $ApiId"
Write-Host "Path: $ApiPath"
Write-Host "OpenAPI: $OpenApiFile"

try {
    Import-AzApiManagementApi `
        -Context (New-AzApiManagementContext -ResourceGroupName $ResourceGroup -ServiceName $ApimName) `
        -SpecificationFormat OpenApi `
        -SpecificationPath $OpenApiFile `
        -Path $ApiPath `
        -ApiId $ApiId `
        -Protocol Https
    
    Write-Host ""
    Write-Host "API imported successfully!" -ForegroundColor Green
    Write-Host "Test at: https://$ApimName.azure-api.net/$ApiPath"
} catch {
    Write-Host "Error importing API: $_" -ForegroundColor Red
    exit 1
}
