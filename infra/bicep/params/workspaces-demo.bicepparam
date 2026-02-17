// Bicep parameters for development environment with workspaces
using '../main.bicep'

param environment = 'dev'
param baseName = 'apim-workspaces-demo'
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
param enableWorkspaces = true
param workspaceConfigs = [
  {
    name: 'dev'
    displayName: 'Development Workspace'
    description: 'Workspace for development and experimentation'
  }
  {
    name: 'test'
    displayName: 'Testing Workspace'
    description: 'Workspace for QA and integration testing'
  }
  {
    name: 'prod'
    displayName: 'Production Workspace'
    description: 'Workspace for production APIs'
  }
]
param tags = {
  Environment: 'dev'
  ManagedBy: 'Bicep'
  Purpose: 'Educational'
  Feature: 'Workspaces'
}
