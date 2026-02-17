// APIM Workspace Bicep module
// Configures workspaces for API segmentation and collaboration

@description('APIM instance name')
param apimName string

@description('Workspace configurations')
param workspaces array = []

// Workspace resources
resource apim 'Microsoft.ApiManagement/service@2023-09-01-preview' existing = {
  name: apimName
}

resource workspace 'Microsoft.ApiManagement/service/workspaces@2023-09-01-preview' = [for ws in workspaces: {
  parent: apim
  name: ws.name
  properties: {
    displayName: ws.displayName
    description: ws.description
  }
}]

// Outputs
@description('Workspace resource IDs')
output workspaceIds array = [for i in range(0, length(workspaces)): workspace[i].id]

@description('Workspace names')
output workspaceNames array = [for ws in workspaces: ws.name]
