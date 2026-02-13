// Diagnostics Bicep module
// Deploys Application Insights and Log Analytics workspace

@description('Azure region')
param location string

@description('Application Insights name')
param appInsightsName string

@description('Log Analytics workspace name')
param logAnalyticsName string

@description('Enable Application Insights')
param enableAppInsights bool

@description('Enable Log Analytics')
param enableLogAnalytics bool

@description('Resource tags')
param tags object

@description('Log Analytics retention in days')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

// Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (enableLogAnalytics) {
  name: logAnalyticsName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: -1  // No cap (use with caution)
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = if (enableAppInsights) {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: enableLogAnalytics ? logAnalytics.id : null
    RetentionInDays: 30
    IngestionMode: enableLogAnalytics ? 'LogAnalytics' : 'ApplicationInsights'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Outputs
@description('Application Insights resource ID')
output appInsightsId string = enableAppInsights ? appInsights.id : ''

@description('Application Insights instrumentation key')
output appInsightsInstrumentationKey string = enableAppInsights ? appInsights.properties.InstrumentationKey : ''

@description('Application Insights connection string')
output appInsightsConnectionString string = enableAppInsights ? appInsights.properties.ConnectionString : ''

@description('Log Analytics workspace ID')
output logAnalyticsId string = enableLogAnalytics ? logAnalytics.id : ''

@description('Log Analytics workspace resource ID')
output logAnalyticsWorkspaceId string = enableLogAnalytics ? logAnalytics.properties.customerId : ''
