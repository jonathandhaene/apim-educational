// Main Bicep template for Azure API Management deployment
// This orchestrates APIM, networking, and diagnostics modules

targetScope = 'resourceGroup'

@description('Environment name (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environment string = 'dev'

@description('Azure region for resources')
param location string = resourceGroup().location

@description('Base name for resources')
param baseName string = 'apim'

@description('APIM SKU name')
@allowed(['Consumption', 'Developer', 'Basic', 'Standard', 'Premium'])
param apimSku string = 'Developer'

@description('APIM capacity (units)')
@minValue(1)
@maxValue(12)
param apimCapacity int = 1

@description('Publisher email for APIM')
param publisherEmail string

@description('Publisher organization name')
param publisherName string

@description('Enable VNet integration')
param enableVNet bool = false

@description('VNet integration type (None, External, Internal)')
@allowed(['None', 'External', 'Internal'])
param vnetType string = 'None'

@description('Enable custom domain')
param enableCustomDomain bool = false

@description('Custom domain hostname (e.g., api.contoso.com)')
param customDomainHostname string = ''

@description('Key Vault resource ID for certificates (if using custom domain)')
param keyVaultId string = ''

@description('Certificate secret name in Key Vault')
param certificateSecretName string = ''

@description('Enable Application Insights')
param enableAppInsights bool = true

@description('Enable Log Analytics')
param enableLogAnalytics bool = true

@description('Tags for all resources')
param tags object = {
  Environment: environment
  ManagedBy: 'Bicep'
  Purpose: 'Educational'
}

// Variables
var resourceNames = {
  apim: '${baseName}-${environment}'
  appInsights: 'appi-${baseName}-${environment}'
  logAnalytics: 'log-${baseName}-${environment}'
  vnet: 'vnet-${baseName}-${environment}'
  subnet: 'snet-${baseName}-${environment}'
  nsg: 'nsg-${baseName}-${environment}'
}

// Module: Diagnostics (Application Insights + Log Analytics)
module diagnostics 'diagnostics.bicep' = if (enableAppInsights || enableLogAnalytics) {
  name: 'diagnostics-deployment'
  params: {
    location: location
    appInsightsName: resourceNames.appInsights
    logAnalyticsName: resourceNames.logAnalytics
    enableAppInsights: enableAppInsights
    enableLogAnalytics: enableLogAnalytics
    tags: tags
  }
}

// Module: Network (VNet, Subnet, NSG)
module network 'network.bicep' = if (enableVNet && vnetType != 'None') {
  name: 'network-deployment'
  params: {
    location: location
    vnetName: resourceNames.vnet
    subnetName: resourceNames.subnet
    nsgName: resourceNames.nsg
    vnetType: vnetType
    tags: tags
  }
}

// Module: API Management
module apim 'apim.bicep' = {
  name: 'apim-deployment'
  params: {
    location: location
    apimName: resourceNames.apim
    apimSku: apimSku
    apimCapacity: apimCapacity
    publisherEmail: publisherEmail
    publisherName: publisherName
    vnetType: vnetType
    subnetId: enableVNet && vnetType != 'None' ? network.outputs.subnetId : ''
    enableCustomDomain: enableCustomDomain
    customDomainHostname: customDomainHostname
    keyVaultId: keyVaultId
    certificateSecretName: certificateSecretName
    appInsightsId: enableAppInsights ? diagnostics.outputs.appInsightsId : ''
    appInsightsInstrumentationKey: enableAppInsights ? diagnostics.outputs.appInsightsInstrumentationKey : ''
    logAnalyticsId: enableLogAnalytics ? diagnostics.outputs.logAnalyticsId : ''
    tags: tags
  }
  dependsOn: [
    network
    diagnostics
  ]
}

// Outputs
@description('API Management service ID')
output apimId string = apim.outputs.apimId

@description('API Management gateway URL')
output apimGatewayUrl string = apim.outputs.gatewayUrl

@description('API Management management URL')
output apimManagementUrl string = apim.outputs.managementUrl

@description('API Management developer portal URL')
output apimPortalUrl string = apim.outputs.portalUrl

@description('Application Insights instrumentation key')
output appInsightsInstrumentationKey string = enableAppInsights ? diagnostics.outputs.appInsightsInstrumentationKey : ''

@description('Log Analytics workspace ID')
output logAnalyticsWorkspaceId string = enableLogAnalytics ? diagnostics.outputs.logAnalyticsWorkspaceId : ''
