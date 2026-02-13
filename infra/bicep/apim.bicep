// API Management Bicep module
// Deploys APIM instance with optional VNet injection, custom domain, and diagnostics

@description('Azure region for APIM')
param location string

@description('APIM instance name')
param apimName string

@description('APIM SKU')
@allowed(['Consumption', 'Developer', 'Basic', 'Standard', 'Premium'])
param apimSku string

@description('APIM capacity')
@minValue(0)
@maxValue(12)
param apimCapacity int

@description('Publisher email')
@minLength(1)
param publisherEmail string

@description('Publisher organization name')
@minLength(1)
param publisherName string

@description('VNet type')
@allowed(['None', 'External', 'Internal'])
param vnetType string

@description('Subnet resource ID for VNet injection')
param subnetId string = ''

@description('Enable custom domain')
param enableCustomDomain bool

@description('Custom domain hostname')
param customDomainHostname string = ''

@description('Key Vault resource ID')
param keyVaultId string = ''

@description('Certificate secret name')
param certificateSecretName string = ''

@description('Application Insights resource ID')
param appInsightsId string = ''

@description('Application Insights instrumentation key')
@secure()
param appInsightsInstrumentationKey string = ''

@description('Log Analytics workspace ID')
param logAnalyticsId string = ''

@description('Resource tags')
param tags object

// APIM instance
resource apim 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  name: apimName
  location: location
  tags: tags
  sku: {
    name: apimSku
    capacity: apimSku == 'Consumption' ? 0 : apimCapacity
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    virtualNetworkType: vnetType
    virtualNetworkConfiguration: vnetType != 'None' && !empty(subnetId) ? {
      subnetResourceId: subnetId
    } : null
    hostnameConfigurations: enableCustomDomain && !empty(customDomainHostname) ? [
      {
        type: 'Proxy'
        hostName: customDomainHostname
        certificateSource: 'KeyVault'
        keyVaultId: '${keyVaultId}/secrets/${certificateSecretName}'
        negotiateClientCertificate: false
        defaultSslBinding: true
      }
    ] : null
  }
}

// Application Insights logger
resource logger 'Microsoft.ApiManagement/service/loggers@2023-05-01-preview' = if (!empty(appInsightsId)) {
  parent: apim
  name: 'app-insights-logger'
  properties: {
    loggerType: 'applicationInsights'
    description: 'Application Insights logger'
    credentials: {
      instrumentationKey: appInsightsInstrumentationKey
    }
    isBuffered: true
    resourceId: appInsightsId
  }
}

// Global diagnostics settings
resource diagnosticSettings 'Microsoft.ApiManagement/service/diagnostics@2023-05-01-preview' = if (!empty(appInsightsId)) {
  parent: apim
  name: 'applicationinsights'
  properties: {
    loggerId: logger.id
    alwaysLog: 'allErrors'
    sampling: {
      samplingType: 'fixed'
      percentage: 100
    }
    frontend: {
      request: {
        headers: ['Content-Type', 'User-Agent', 'Ocp-Apim-Subscription-Key']
        body: {
          bytes: 1024
        }
      }
      response: {
        headers: ['Content-Type']
        body: {
          bytes: 1024
        }
      }
    }
    backend: {
      request: {
        headers: ['Content-Type']
        body: {
          bytes: 1024
        }
      }
      response: {
        headers: ['Content-Type']
        body: {
          bytes: 1024
        }
      }
    }
  }
}

// Diagnostic settings for Azure Monitor
resource monitorDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsId)) {
  name: '${apimName}-diagnostics'
  scope: apim
  properties: {
    workspaceId: logAnalyticsId
    logs: [
      {
        category: 'GatewayLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
      {
        category: 'WebSocketConnectionLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
    ]
  }
}

// Named values (example - add more as needed)
resource namedValue 'Microsoft.ApiManagement/service/namedValues@2023-05-01-preview' = {
  parent: apim
  name: 'environment'
  properties: {
    displayName: 'environment'
    value: tags.Environment
    secret: false
  }
}

// Outputs
@description('APIM resource ID')
output apimId string = apim.id

@description('APIM gateway URL')
output gatewayUrl string = apim.properties.gatewayUrl

@description('APIM management URL')
output managementUrl string = apim.properties.managementApiUrl

@description('APIM developer portal URL')
output portalUrl string = apim.properties.portalUrl

@description('APIM principal ID (Managed Identity)')
output principalId string = apim.identity.principalId

@description('APIM private IP addresses (VNet mode)')
output privateIPAddresses array = vnetType != 'None' ? apim.properties.privateIPAddresses : []
