# Bicep Infrastructure Templates

This directory contains modular Bicep templates for deploying Azure API Management infrastructure.

## Structure

```
bicep/
├── main.bicep           # Main orchestration template
├── apim.bicep          # APIM instance module
├── network.bicep       # VNet, Subnet, NSG module
├── diagnostics.bicep   # App Insights, Log Analytics module
└── params/             # Parameter files
    ├── public-dev.bicepparam    # Public APIM (dev)
    └── internal.bicepparam      # Internal VNet mode
```

## Quick Start

### Prerequisites

- Azure CLI with Bicep support
- Azure subscription
- Contributor access to target resource group

### Deploy Public Development Instance

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "<your-subscription-id>"

# Create resource group
az group create --name rg-apim-dev --location eastus

# Deploy with parameter file
az deployment group create \
  --resource-group rg-apim-dev \
  --template-file main.bicep \
  --parameters params/public-dev.bicepparam
```

### Deploy Internal (VNet) Instance

```bash
# Create resource group
az group create --name rg-apim-internal --location eastus

# Deploy with parameter file
az deployment group create \
  --resource-group rg-apim-internal \
  --template-file main.bicep \
  --parameters params/internal.bicepparam
```

### Deploy with Custom Parameters

```bash
az deployment group create \
  --resource-group rg-apim-dev \
  --template-file main.bicep \
  --parameters \
    environment=dev \
    baseName=myapi \
    apimSku=Developer \
    publisherEmail=admin@example.com \
    publisherName="My Organization" \
    enableVNet=false
```

## Parameters

### Required Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `publisherEmail` | APIM publisher email | `admin@contoso.com` |
| `publisherName` | Organization name | `Contoso Corp` |

### Optional Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `environment` | `dev` | Environment name (dev/staging/prod) |
| `baseName` | `apim` | Base name for resources |
| `apimSku` | `Developer` | APIM SKU tier |
| `apimCapacity` | `1` | Number of APIM units |
| `enableVNet` | `false` | Enable VNet integration |
| `vnetType` | `None` | VNet type (None/External/Internal) |
| `enableCustomDomain` | `false` | Enable custom domain |
| `enableAppInsights` | `true` | Enable Application Insights |
| `enableLogAnalytics` | `true` | Enable Log Analytics |

## Features

### API Management

- ✅ System-assigned Managed Identity
- ✅ Application Insights integration
- ✅ Log Analytics diagnostics
- ✅ Optional VNet injection (External/Internal)
- ✅ Optional custom domain with Key Vault certificates
- ✅ Named values for configuration

### Networking

- ✅ VNet with configurable address space
- ✅ Dedicated subnet for APIM
- ✅ NSG with required rules for APIM
- ✅ Service endpoints (Storage, SQL, Key Vault, Event Hub)

### Diagnostics

- ✅ Application Insights for distributed tracing
- ✅ Log Analytics workspace for centralized logging
- ✅ APIM logger configuration
- ✅ Diagnostic settings for gateway logs

## Validation

### Validate Templates

```bash
# Validate main template
az deployment group validate \
  --resource-group rg-apim-dev \
  --template-file main.bicep \
  --parameters params/public-dev.bicepparam

# What-if deployment (preview changes)
az deployment group what-if \
  --resource-group rg-apim-dev \
  --template-file main.bicep \
  --parameters params/public-dev.bicepparam
```

### Build Bicep Locally

```bash
# Compile to ARM template
az bicep build --file main.bicep

# Decompile ARM template to Bicep
az bicep decompile --file main.json
```

## Customization

### Add Custom Named Values

Edit `apim.bicep` and add more named values:

```bicep
resource namedValueBackendUrl 'Microsoft.ApiManagement/service/namedValues@2023-05-01-preview' = {
  parent: apim
  name: 'backend-url'
  properties: {
    displayName: 'backend-url'
    value: 'https://backend.example.com'
    secret: false
  }
}
```

### Add Custom Domains

Update parameters:

```bicep
param enableCustomDomain = true
param customDomainHostname = 'api.contoso.com'
param keyVaultId = '/subscriptions/.../providers/Microsoft.KeyVault/vaults/kv-contoso'
param certificateSecretName = 'api-contoso-cert'
```

### Configure Multi-Region (Premium Tier)

For multi-region deployment, use Premium SKU and add additional locations in `apim.bicep`:

```bicep
properties: {
  additionalLocations: [
    {
      location: 'westeurope'
      sku: {
        name: 'Premium'
        capacity: 1
      }
    }
  ]
}
```

## Outputs

After successful deployment, you'll receive:

- **apimId**: APIM resource ID
- **apimGatewayUrl**: Gateway endpoint (e.g., `https://apim-dev.azure-api.net`)
- **apimManagementUrl**: Management API endpoint
- **apimPortalUrl**: Developer portal URL
- **appInsightsInstrumentationKey**: For application logging
- **logAnalyticsWorkspaceId**: For log queries

## Cost Estimation

Use Azure Pricing Calculator to estimate costs:

**Example (Developer tier, East US):**
- APIM Developer: ~$50/month
- Application Insights: ~$10-50/month (depending on usage)
- Log Analytics: ~$5-20/month (depending on ingestion)
- **Total**: ~$65-120/month

**Tip**: Delete resources when not in use to avoid charges.

## Troubleshooting

### Common Issues

**Issue**: VNet deployment fails
- **Solution**: Ensure subnet is empty and /27 or larger

**Issue**: Custom domain fails
- **Solution**: Grant APIM Managed Identity "Get Secrets" permission on Key Vault

**Issue**: Deployment takes long time
- **Note**: APIM provisioning can take 30-45 minutes

### Get Deployment Logs

```bash
az deployment group show \
  --resource-group rg-apim-dev \
  --name main \
  --query properties.error
```

## Next Steps

- [Deploy scripts](../../scripts/) for automated deployment
- [Parameter reference](../../docs/tiers-and-skus.md) for SKU selection
- [Networking guide](../../docs/networking.md) for VNet configuration
- [Security guide](../../docs/security.md) for hardening

---

**Happy deploying!** For issues, open a GitHub issue or see [troubleshooting guide](../../docs/troubleshooting.md).
