# Azure API Management Networking Guide

This guide covers network configuration options for Azure API Management, from public deployments to fully private architectures.

## Table of Contents
- [Network Deployment Modes](#network-deployment-modes)
- [VNet Integration](#vnet-integration)
- [Private Endpoints](#private-endpoints)
- [Custom Domains](#custom-domains)
- [DNS Configuration](#dns-configuration)
- [Network Security Groups](#network-security-groups)
- [Connectivity Patterns](#connectivity-patterns)

## Network Deployment Modes

### 1. Public (Default)

APIM is deployed with public endpoints accessible from the internet.

**Characteristics:**
- Gateway endpoint: Public DNS and IP
- Management endpoint: Public (portal, API)
- Developer portal: Public
- No VNet required

**Use cases:**
- Public-facing APIs
- Development and testing
- Simple scenarios
- Consumption and Developer tiers

**Diagram:**
```
Internet → [APIM Gateway] → Backend Services
            (Public IP)
```

### 2. External VNet

APIM is injected into a VNet but endpoints remain publicly accessible with internet-facing IPs.

**Characteristics:**
- Gateway: Public IP, routed via VNet
- Backends: Can be private (within VNet)
- Management: Public
- Available: Developer, Premium tiers only

**Use cases:**
- Public APIs with private backends
- IaaS backends (VMs, Azure SQL with VNet)
- On-premises backends via ExpressRoute/VPN

**Diagram:**
```
Internet → [VNet - Public Subnet]
           [APIM Gateway]
                ↓
           [Private Subnet]
           [Backend VMs/Services]
```

### 3. Internal VNet

APIM is injected into a VNet with private endpoints only; no public access by default.

**Characteristics:**
- Gateway: Private IP only
- Management: Accessible via VNet or public (configurable)
- Developer portal: Private IP
- Available: Developer, Premium tiers only

**Use cases:**
- Internal corporate APIs
- Private APIs for VNet-connected clients
- ExpressRoute or VPN-connected on-premises clients

**Diagram:**
```
Corporate Network (VPN/ExpressRoute)
       ↓
   [VNet - Private Subnet]
   [APIM Gateway - Private IP]
       ↓
   [Backend Services]
```

### 4. Private Endpoint (Newer Option)

Use Azure Private Link to connect to APIM without VNet injection (available for Consumption, Developer, Basic, Standard, Premium tiers).

**Characteristics:**
- APIM remains in Microsoft-managed VNet
- Private endpoint created in your VNet
- Works with all tiers (including Consumption)
- Simpler than VNet injection

**Use cases:**
- Private access without tier upgrade
- Multi-VNet connectivity
- Simplified networking

## VNet Integration

### Prerequisites

- **Tier**: Developer or Premium only for VNet injection
- **VNet**: Existing Azure VNet
- **Subnet**: Dedicated subnet for APIM (minimum /29, recommended /27 or larger)
- **NSG**: Network Security Group with required rules
- **Service Endpoints**: Microsoft.Storage, Microsoft.Sql (if using)

### External VNet Deployment

**Bicep Example:**
```bicep
resource apim 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  name: 'apim-external-example'
  location: location
  sku: {
    name: 'Developer'
    capacity: 1
  }
  properties: {
    publisherEmail: 'admin@example.com'
    publisherName: 'Example Org'
    virtualNetworkType: 'External'
    virtualNetworkConfiguration: {
      subnetResourceId: subnet.id
    }
  }
}
```

**Key Considerations:**
- APIM will have both public and private IPs
- Backends can be accessed via private VNet routes
- Traffic flows: Internet → Public IP → VNet routing → Backends

### Internal VNet Deployment

**Bicep Example:**
```bicep
resource apim 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  name: 'apim-internal-example'
  location: location
  sku: {
    name: 'Premium'
    capacity: 1
  }
  properties: {
    publisherEmail: 'admin@example.com'
    publisherName: 'Example Org'
    virtualNetworkType: 'Internal'
    virtualNetworkConfiguration: {
      subnetResourceId: subnet.id
    }
  }
}
```

**Key Considerations:**
- No public gateway IP by default
- Requires Application Gateway or Azure Front Door for public access
- Management endpoint can remain public or use private
- Clients must be on VNet or connected via VPN/ExpressRoute

### Subnet Sizing

| Capacity Units | Minimum Subnet Size | Recommended |
|----------------|---------------------|-------------|
| 1              | /29 (8 IPs)        | /27 (32 IPs)|
| 2              | /28 (16 IPs)       | /26 (64 IPs)|
| 3+             | /27 (32 IPs)       | /25 (128 IPs)|

**Note**: Azure reserves 5 IPs per subnet; APIM needs multiple IPs for updates and failover.

## Private Endpoints

Private Endpoint provides private connectivity without VNet injection.

### Benefits

- **Any Tier**: Works with Consumption, Developer, Basic, Standard, Premium
- **Simplified**: No NSG rules or subnet delegation required
- **Multi-VNet**: Connect from multiple VNets via peering
- **Hub-Spoke**: Centralized APIM, spoke VNets connect via private endpoints

### Setup

**1. Create Private Endpoint:**
```bash
az network private-endpoint create \
  --name pe-apim-gateway \
  --resource-group rg-apim \
  --vnet-name vnet-corp \
  --subnet snet-privatelinks \
  --private-connection-resource-id /subscriptions/.../Microsoft.ApiManagement/service/apim-instance \
  --group-id Gateway \
  --connection-name apim-gateway-connection
```

**2. Configure Private DNS:**
```bash
az network private-dns zone create \
  --resource-group rg-apim \
  --name privatelink.azure-api.net

az network private-dns link vnet create \
  --resource-group rg-apim \
  --zone-name privatelink.azure-api.net \
  --name dns-link \
  --virtual-network vnet-corp \
  --registration-enabled false
```

**3. Create DNS Record:**
```bash
az network private-endpoint dns-zone-group create \
  --resource-group rg-apim \
  --endpoint-name pe-apim-gateway \
  --name zone-group \
  --private-dns-zone privatelink.azure-api.net \
  --zone-name apim
```

### Subresources

- **Gateway**: API gateway endpoint
- **Management**: Management API endpoint
- **Portal**: Developer portal endpoint
- **Scm**: Git-based configuration repository

## Custom Domains

### Why Custom Domains?

- Branding: `api.contoso.com` instead of `contoso.azure-api.net`
- Consistency: Same domain across environments
- Certificate control: Use your own TLS certificates
- Multi-region: Different domains per region

### Domain Types

1. **Gateway**: API endpoints (`api.contoso.com`)
2. **Management**: Management API (`management.contoso.com`)
3. **Portal**: Developer portal (`portal.contoso.com`)
4. **Scm**: Git config (`scm.contoso.com`)

### Configuration

**Bicep Example:**
```bicep
resource apim 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  name: 'apim-custom-domain'
  location: location
  sku: {
    name: 'Premium'
    capacity: 1
  }
  properties: {
    publisherEmail: 'admin@contoso.com'
    publisherName: 'Contoso'
    hostnameConfigurations: [
      {
        type: 'Proxy'
        hostName: 'api.contoso.com'
        certificateSource: 'KeyVault'
        keyVaultId: 'https://keyvault.vault.azure.net/secrets/api-contoso-cert'
        identityClientId: apimIdentity.properties.clientId
        negotiateClientCertificate: false
        defaultSslBinding: true
      }
      {
        type: 'DeveloperPortal'
        hostName: 'portal.contoso.com'
        certificateSource: 'KeyVault'
        keyVaultId: 'https://keyvault.vault.azure.net/secrets/portal-contoso-cert'
        identityClientId: apimIdentity.properties.clientId
      }
    ]
  }
  identity: {
    type: 'SystemAssigned'
  }
}
```

### Certificate Requirements

- **Format**: PFX or Key Vault reference
- **Wildcard**: Supported (e.g., `*.contoso.com`)
- **Chain**: Include intermediate certificates
- **Expiry**: Monitor and rotate before expiration
- **Storage**: Use Azure Key Vault with Managed Identity

## DNS Configuration

### Public Scenario

```
api.contoso.com → CNAME → apim-instance.azure-api.net → Public IP
```

**DNS Records:**
```
api.contoso.com.     CNAME   apim-instance.azure-api.net.
```

### Internal VNet Scenario

```
api.contoso.com → A Record → Private IP (10.0.1.5)
```

**Private DNS Zone:**
```
Private DNS Zone: contoso.com
A Record: api.contoso.com → 10.0.1.5
```

### Multi-Region

Use Traffic Manager or Front Door:
```
api.contoso.com → CNAME → apim-tm.trafficmanager.net
                          ├─ East US: apim-eus.azure-api.net
                          └─ West Europe: apim-weu.azure-api.net
```

## Network Security Groups

### Required Inbound Rules (External VNet)

| Priority | Source          | Source Port | Destination | Dest Port | Protocol | Purpose           |
|----------|-----------------|-------------|-------------|-----------|----------|-------------------|
| 100      | Internet        | *           | VirtualNetwork | 80,443   | TCP      | Client to Gateway |
| 110      | ApiManagement   | *           | VirtualNetwork | 3443     | TCP      | Management        |
| 120      | AzureLoadBalancer| *          | VirtualNetwork | 6390     | TCP      | Health Probe      |

### Required Outbound Rules

| Priority | Destination      | Dest Port | Protocol | Purpose                    |
|----------|------------------|-----------|----------|----------------------------|
| 100      | Storage          | 443       | TCP      | Dependency on Azure Storage|
| 110      | Sql              | 1433      | TCP      | Dependency on Azure SQL    |
| 120      | AzureKeyVault    | 443       | TCP      | Key Vault access           |
| 130      | EventHub         | 443,5671,5672 | TCP  | Logging to Event Hub       |
| 140      | AzureMonitor     | 443,1886  | TCP      | Diagnostics and Monitoring |

### Required Inbound Rules (Internal VNet)

Same as External, except:
- Port 80/443: Change source from `Internet` to `VirtualNetwork` or specific subnet/IP ranges

### NSG Example

```bicep
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: 'nsg-apim-subnet'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowGatewayInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: ['80', '443']
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: 'VirtualNetwork'
        }
      }
      {
        name: 'AllowManagementInbound'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3443'
          sourceAddressPrefix: 'ApiManagement'
          destinationAddressPrefix: 'VirtualNetwork'
        }
      }
      // Additional rules...
    ]
  }
}
```

## Connectivity Patterns

### Pattern 1: Public APIs with Azure Backends

```
Internet → APIM (Public) → Azure PaaS Services
                           (App Service, Functions, Logic Apps)
```

- APIM: Public deployment (default)
- Backends: Azure PaaS with public endpoints
- Security: Subscription keys, JWT validation

### Pattern 2: Public APIs with Private Backends

```
Internet → APIM (External VNet) → Private VNet
                                   (VMs, AKS, Private Endpoints)
```

- APIM: External VNet mode
- Backends: Private IPs in VNet
- Security: APIM acts as ingress controller

### Pattern 3: Fully Private Internal APIs

```
Corporate Network (VPN) → APIM (Internal VNet) → Private Backends
```

- APIM: Internal VNet mode
- All communication: Private IPs
- Access: VPN or ExpressRoute

### Pattern 4: Internal APIs with Public Facade

```
Internet → Application Gateway/Front Door → APIM (Internal VNet) → Private Backends
```

- APIM: Internal VNet mode
- Public access: Via App Gateway WAF or Front Door
- Security: DDoS protection, WAF, geo-filtering

### Pattern 5: Multi-Region with Traffic Manager

```
Internet → Traffic Manager
           ├─ Region 1: APIM + Backends
           └─ Region 2: APIM + Backends
```

- APIM: Premium tier with multi-region deployment
- Traffic Manager: DNS-based routing (performance, priority, failover)
- Backends: Regional deployment

### Pattern 6: Hybrid with ExpressRoute

```
On-Premises → ExpressRoute → Azure VNet → APIM → Cloud Backends
                                        ↓
                                   On-Prem Backends
```

- APIM: External or Internal VNet
- ExpressRoute: Private connection to Azure
- Backends: Mix of cloud and on-premises

### Pattern 7: Hub-Spoke with Private Endpoints

```
Hub VNet: [APIM - Private Endpoint]
          ├─ Spoke 1: App Services
          ├─ Spoke 2: AKS
          └─ Spoke 3: On-Premises (VPN)
```

- APIM: Consumption/Basic/Standard/Premium with Private Endpoint
- Topology: Hub-spoke with VNet peering
- Benefits: Centralized, scalable, cost-effective

## Troubleshooting

### Common Issues

**Issue**: Cannot reach APIM gateway
- Check NSG rules allow traffic
- Verify DNS resolution (nslookup)
- Confirm firewall rules permit 443/80

**Issue**: VNet injection fails
- Subnet must be empty (no other resources)
- NSG must have required rules
- Subnet must be /27 or larger (recommended)

**Issue**: Custom domain not working
- Verify DNS CNAME/A record
- Check certificate validity and trust chain
- Ensure Key Vault access via Managed Identity

**Issue**: Can't reach private backend
- Verify VNet peering or VPN/ExpressRoute
- Check backend firewall/NSG rules
- Test connectivity from APIM subnet (Network Watcher)

### Diagnostic Commands

```bash
# Check APIM network status
az apim show --name apim-instance --resource-group rg-apim --query "virtualNetworkType"

# Verify DNS resolution
nslookup api.contoso.com

# Test connectivity from VNet
az network watcher test-ip-flow \
  --resource-group rg-apim \
  --vm apim-instance \
  --direction outbound \
  --protocol tcp \
  --local 10.0.1.5:443 \
  --remote 10.0.2.10:443
```

## Best Practices

1. **Plan subnet size**: Use /26 or /27 for growth and updates
2. **Use Private Endpoints**: When VNet injection isn't required
3. **Implement NSG rules**: Allow only necessary traffic
4. **Use Custom Domains**: For production workloads
5. **Enable diagnostics**: Log network traffic for troubleshooting
6. **Test connectivity**: Before full deployment
7. **Document network design**: Maintain architecture diagrams
8. **Use Application Gateway**: For WAF with Internal VNet mode
9. **Plan for multi-region**: If availability is critical
10. **Monitor network health**: Set up alerts on connectivity issues

## Next Steps

- [Security Guide](security.md) - Implement authentication and authorization
- [Tiers and SKUs](tiers-and-skus.md) - Choose appropriate tier for your network requirements
- [Front Door Integration](front-door.md) - Add CDN and WAF capabilities

---

**Questions?** Open an issue or contribute improvements!
