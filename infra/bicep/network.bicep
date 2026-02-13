// Network Bicep module
// Deploys VNet, Subnet, and NSG for APIM

@description('Azure region')
param location string

@description('VNet name')
param vnetName string

@description('Subnet name')
param subnetName string

@description('NSG name')
param nsgName string

@description('VNet integration type')
@allowed(['None', 'External', 'Internal'])
param vnetType string

@description('Resource tags')
param tags object

@description('VNet address prefix')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Subnet address prefix')
param subnetAddressPrefix string = '10.0.1.0/24'

// Network Security Group
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      // Inbound rules for APIM
      {
        name: 'AllowClientToGateway'
        properties: {
          description: 'Allow client traffic to API gateway'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: [
            '80'
            '443'
          ]
          sourceAddressPrefix: vnetType == 'External' ? 'Internet' : 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowManagementEndpoint'
        properties: {
          description: 'Management endpoint for Azure portal and PowerShell'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3443'
          sourceAddressPrefix: 'ApiManagement'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowLoadBalancer'
        properties: {
          description: 'Azure Infrastructure Load Balancer'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '6390'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      // Outbound rules for APIM
      {
        name: 'AllowStorageOutbound'
        properties: {
          description: 'Dependency on Azure Storage'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Storage'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowSqlOutbound'
        properties: {
          description: 'Dependency on Azure SQL'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '1433'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Sql'
          access: 'Allow'
          priority: 110
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowKeyVaultOutbound'
        properties: {
          description: 'Dependency on Azure Key Vault'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureKeyVault'
          access: 'Allow'
          priority: 120
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowMonitorOutbound'
        properties: {
          description: 'Monitoring and diagnostics'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: [
            '443'
            '1886'
            '12000-12001'
          ]
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureMonitor'
          access: 'Allow'
          priority: 130
          direction: 'Outbound'
        }
      }
    ]
  }
}

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          networkSecurityGroup: {
            id: nsg.id
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
            }
            {
              service: 'Microsoft.Sql'
            }
            {
              service: 'Microsoft.KeyVault'
            }
            {
              service: 'Microsoft.EventHub'
            }
          ]
          delegations: []
        }
      }
    ]
  }
}

// Outputs
@description('VNet resource ID')
output vnetId string = vnet.id

@description('Subnet resource ID')
output subnetId string = vnet.properties.subnets[0].id

@description('NSG resource ID')
output nsgId string = nsg.id

@description('Subnet address prefix')
output subnetAddressPrefix string = subnetAddressPrefix
