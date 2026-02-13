// Bicep parameters for public development environment
using '../main.bicep'

param environment = 'dev'
param baseName = 'apim-educational'
param apimSku = 'Developer'
param apimCapacity = 1
param publisherEmail = 'admin@example.com'  // TODO: Replace with your email
param publisherName = 'Educational Org'      // TODO: Replace with your org name
param enableVNet = false
param vnetType = 'None'
param enableCustomDomain = false
param customDomainHostname = ''
param keyVaultId = ''
param certificateSecretName = ''
param enableAppInsights = true
param enableLogAnalytics = true
param tags = {
  Environment: 'dev'
  ManagedBy: 'Bicep'
  Purpose: 'Educational'
  CostCenter: 'IT'  // TODO: Update as needed
}
