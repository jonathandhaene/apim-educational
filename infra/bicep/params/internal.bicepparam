// Bicep parameters for internal (VNet-integrated) environment
using '../main.bicep'

param environment = 'staging'
param baseName = 'apim-educational'
param apimSku = 'Developer'  // Or 'Premium' for production
param apimCapacity = 1
param publisherEmail = 'admin@example.com'  // TODO: Replace with your email
param publisherName = 'Educational Org'      // TODO: Replace with your org name
param enableVNet = true
param vnetType = 'Internal'  // 'Internal' for fully private, 'External' for public gateway with private backends
param enableCustomDomain = false
param customDomainHostname = 'api-internal.contoso.com'  // TODO: Replace with your domain
param keyVaultId = ''  // TODO: Add Key Vault resource ID if using custom domain
param certificateSecretName = ''  // TODO: Add certificate secret name
param enableAppInsights = true
param enableLogAnalytics = true
param tags = {
  Environment: 'staging'
  ManagedBy: 'Bicep'
  Purpose: 'Educational'
  CostCenter: 'IT'  // TODO: Update as needed
  NetworkType: 'Internal'
}
