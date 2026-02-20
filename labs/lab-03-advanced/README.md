# Lab 3: Advanced - VNet Integration, Private Endpoints, and Key Vault

**Level**: Advanced  
**Duration**: 90-120 minutes  
**Prerequisites**: Completed Lab 2 or have APIM with diagnostics configured

> **⚠️ Educational Disclaimer**: This repository is provided for educational and learning purposes only. All content, including pricing estimates, tier recommendations, and infrastructure templates, should be validated and adapted for your specific production requirements. Azure API Management features, pricing, and best practices evolve frequently—always consult the <a href="https://learn.microsoft.com/azure/api-management/">official Azure documentation</a> and <a href="https://azure.microsoft.com/pricing/calculator/">Azure Pricing Calculator</a> for the most current information before making production decisions.

## Learning Objectives

By the end of this lab, you will:
- Configure Azure Virtual Network (VNet) integration for internal/private APIM mode
- Set up private endpoints for secure access to APIM
- Integrate Azure Key Vault for secrets management with Managed Identity
- Implement API versioning and revision strategies
- Configure custom domains (placeholder approach)

## Architecture

```
Private VNet
  ├── APIM (Internal Mode)
  │   ├── Private Endpoint
  │   └── Managed Identity → Key Vault
  ├── Backend Services (Private)
  └── Azure Bastion (Management Access)

Custom Domain (Optional)
  └── Certificate from Key Vault
```

## Prerequisites

- Completed [Lab 2: Intermediate](../lab-02-intermediate/README.md)
- Azure CLI and PowerShell/Bash
- Understanding of Azure networking concepts
- Premium or Developer tier APIM (required for VNet injection)

## Step 1: Configure VNet Integration

### Create VNet and Subnet

```bash
# Set variables
RESOURCE_GROUP="rg-apim-lab"
LOCATION="eastus"
VNET_NAME="vnet-apim"
APIM_SUBNET="subnet-apim"
APIM_NAME="apim-lab-yourname"

# Create VNet
az network vnet create \
  --resource-group ${RESOURCE_GROUP} \
  --name ${VNET_NAME} \
  --address-prefix 10.0.0.0/16 \
  --location ${LOCATION}

# Create subnet for APIM (requires /28 minimum)
az network vnet subnet create \
  --resource-group ${RESOURCE_GROUP} \
  --vnet-name ${VNET_NAME} \
  --name ${APIM_SUBNET} \
  --address-prefix 10.0.1.0/24

# Get subnet ID
SUBNET_ID=$(az network vnet subnet show \
  --resource-group ${RESOURCE_GROUP} \
  --vnet-name ${VNET_NAME} \
  --name ${APIM_SUBNET} \
  --query id -o tsv)
```

### Deploy APIM with VNet Integration

Use Bicep or Terraform template from [../../infra/bicep/](../../infra/bicep/) or [../../infra/terraform/](../../infra/terraform/).

**Option A: Deploy new APIM with internal mode**:

```bash
# Use Bicep template with internal network mode
cd ../../infra/bicep

# Edit params/internal.bicepparam with your VNet/subnet info
# Then deploy:
az deployment group create \
  --resource-group ${RESOURCE_GROUP} \
  --template-file main.bicep \
  --parameters @params/internal.bicepparam
```

**Option B: Update existing APIM (requires downtime)**:

```bash
# Note: Switching to internal mode requires APIM to be in Premium tier
# and causes temporary downtime

az apim update \
  --name ${APIM_NAME} \
  --resource-group ${RESOURCE_GROUP} \
  --virtual-network Internal \
  --subnet-id ${SUBNET_ID}

# This operation takes 45-60 minutes
```

### Validation

```bash
# Check APIM network configuration
az apim show \
  --name ${APIM_NAME} \
  --resource-group ${RESOURCE_GROUP} \
  --query "virtualNetworkConfiguration" -o json

# Get private IP address
APIM_PRIVATE_IP=$(az apim show \
  --name ${APIM_NAME} \
  --resource-group ${RESOURCE_GROUP} \
  --query "privateIPAddresses[0]" -o tsv)

echo "APIM Private IP: ${APIM_PRIVATE_IP}"
```

**Expected Output**: Shows VNet configuration with subnet ID and private IP address.

## Step 2: Configure Private Endpoint

### Create Private Endpoint

```bash
# Create private endpoint subnet
az network vnet subnet create \
  --resource-group ${RESOURCE_GROUP} \
  --vnet-name ${VNET_NAME} \
  --name subnet-privatelink \
  --address-prefix 10.0.2.0/24 \
  --disable-private-endpoint-network-policies true

# Create private endpoint for APIM
az network private-endpoint create \
  --resource-group ${RESOURCE_GROUP} \
  --name pe-apim \
  --vnet-name ${VNET_NAME} \
  --subnet subnet-privatelink \
  --private-connection-resource-id $(az apim show --name ${APIM_NAME} --resource-group ${RESOURCE_GROUP} --query id -o tsv) \
  --group-id Gateway \
  --connection-name apim-pe-connection

# Create Private DNS Zone
az network private-dns zone create \
  --resource-group ${RESOURCE_GROUP} \
  --name privatelink.azure-api.net

# Link DNS zone to VNet
az network private-dns link vnet create \
  --resource-group ${RESOURCE_GROUP} \
  --zone-name privatelink.azure-api.net \
  --name apim-dns-link \
  --virtual-network ${VNET_NAME} \
  --registration-enabled false

# Create DNS record
az network private-endpoint dns-zone-group create \
  --resource-group ${RESOURCE_GROUP} \
  --endpoint-name pe-apim \
  --name apim-zone-group \
  --private-dns-zone privatelink.azure-api.net \
  --zone-name privatelink.azure-api.net
```

### Test Private Endpoint

From a VM in the same VNet:

```bash
# Resolve DNS (should return private IP)
nslookup ${APIM_NAME}.azure-api.net

# Test API call
curl "https://${APIM_NAME}.azure-api.net/sample/httpTrigger?name=PrivateTest" \
  -H "Ocp-Apim-Subscription-Key: ${SUBSCRIPTION_KEY}"
```

**Expected Output**: DNS resolves to private IP (10.0.x.x), API call succeeds from within VNet.

## Step 3: Integrate Azure Key Vault

### Create Key Vault with Managed Identity

```bash
# Create Key Vault
KV_NAME="kv-apim-${RANDOM}"
az keyvault create \
  --name ${KV_NAME} \
  --resource-group ${RESOURCE_GROUP} \
  --location ${LOCATION} \
  --enable-rbac-authorization false

# Enable system-assigned managed identity for APIM
az apim update \
  --name ${APIM_NAME} \
  --resource-group ${RESOURCE_GROUP} \
  --set identity.type=SystemAssigned

# Get managed identity principal ID
MI_PRINCIPAL_ID=$(az apim show \
  --name ${APIM_NAME} \
  --resource-group ${RESOURCE_GROUP} \
  --query identity.principalId -o tsv)

# Grant APIM access to Key Vault secrets
az keyvault set-policy \
  --name ${KV_NAME} \
  --resource-group ${RESOURCE_GROUP} \
  --object-id ${MI_PRINCIPAL_ID} \
  --secret-permissions get list

echo "Key Vault: ${KV_NAME}"
echo "Managed Identity granted access"
```

### Store Backend API Key in Key Vault

```bash
# Add a secret (e.g., backend API key)
az keyvault secret set \
  --vault-name ${KV_NAME} \
  --name backend-api-key \
  --value "your-backend-api-key-here"

# Get secret identifier
SECRET_ID=$(az keyvault secret show \
  --vault-name ${KV_NAME} \
  --name backend-api-key \
  --query id -o tsv)

echo "Secret ID: ${SECRET_ID}"
```

### Create Named Value in APIM

```bash
# Via Azure CLI (using Portal is often easier for Named Values)
# Navigate to: APIM → Named values → Add

# Or use API:
az rest --method put \
  --uri "https://management.azure.com/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/namedValues/backend-api-key?api-version=2021-08-01" \
  --body "{
    \"properties\": {
      \"displayName\": \"backend-api-key\",
      \"keyVault\": {
        \"secretIdentifier\": \"${SECRET_ID}\"
      },
      \"secret\": true
    }
  }"
```

### Use Named Value in Policy

```xml
<inbound>
    <base />
    <set-header name="X-API-Key" exists-action="override">
        <value>{{backend-api-key}}</value>
    </set-header>
</inbound>
```

### Validation

```bash
# Test API call - backend should receive the Key Vault secret as header
curl "https://${APIM_NAME}.azure-api.net/sample/httpTrigger?name=KeyVaultTest" \
  -H "Ocp-Apim-Subscription-Key: ${SUBSCRIPTION_KEY}" \
  -v 2>&1 | grep "X-API-Key"
```

**Expected Output**: Backend receives `X-API-Key` header with value from Key Vault.

## Step 4: API Versioning Strategy

### Create Version Set

```bash
# Via Portal: APIs → Version sets → Add
# Or use CLI:
VERSION_SET_ID=$(az apim api versionset create \
  --resource-group ${RESOURCE_GROUP} \
  --service-name ${APIM_NAME} \
  --version-set-id sample-api-versions \
  --display-name "Sample API Versions" \
  --versioning-scheme Segment \
  --query id -o tsv)

echo "Version Set ID: ${VERSION_SET_ID}"
```

### Create Versioned APIs

```bash
# Create v1 API
az apim api create \
  --resource-group ${RESOURCE_GROUP} \
  --service-name ${APIM_NAME} \
  --api-id sample-api-v1 \
  --path sample/v1 \
  --display-name "Sample API v1" \
  --protocols https \
  --api-version v1 \
  --api-version-set-id ${VERSION_SET_ID}

# Create v2 API with new features
az apim api create \
  --resource-group ${RESOURCE_GROUP} \
  --service-name ${APIM_NAME} \
  --api-id sample-api-v2 \
  --path sample/v2 \
  --display-name "Sample API v2" \
  --protocols https \
  --api-version v2 \
  --api-version-set-id ${VERSION_SET_ID}
```

### Test Versions

```bash
# Test v1
curl "https://${APIM_NAME}.azure-api.net/sample/v1/httpTrigger?name=V1" \
  -H "Ocp-Apim-Subscription-Key: ${SUBSCRIPTION_KEY}"

# Test v2
curl "https://${APIM_NAME}.azure-api.net/sample/v2/httpTrigger?name=V2" \
  -H "Ocp-Apim-Subscription-Key: ${SUBSCRIPTION_KEY}"
```

## Step 5: API Revisions for Safe Deployment

### Create Revision

```bash
# Create a new revision for testing changes
az apim api revision create \
  --resource-group ${RESOURCE_GROUP} \
  --service-name ${APIM_NAME} \
  --api-id sample-api-v1 \
  --api-revision 2 \
  --api-revision-description "Testing new rate limits"

# The revision is accessible at:
# https://{apim-name}.azure-api.net/sample/v1;rev=2/httpTrigger
```

### Make Changes to Revision

```bash
# Update policy for revision 2 only
# Navigate to: APIM → APIs → sample-api-v1;rev=2 → Policies
# Make your changes (e.g., adjust rate limits)
```

### Test Revision

```bash
# Test revision 2 (non-current)
curl "https://${APIM_NAME}.azure-api.net/sample/v1;rev=2/httpTrigger?name=Rev2" \
  -H "Ocp-Apim-Subscription-Key: ${SUBSCRIPTION_KEY}"

# Test current revision (still rev=1)
curl "https://${APIM_NAME}.azure-api.net/sample/v1/httpTrigger?name=Current" \
  -H "Ocp-Apim-Subscription-Key: ${SUBSCRIPTION_KEY}"
```

### Make Revision Current

```bash
# After testing, make revision 2 the current revision
az apim api release create \
  --resource-group ${RESOURCE_GROUP} \
  --service-name ${APIM_NAME} \
  --api-id sample-api-v1 \
  --api-revision 2 \
  --notes "Deployed new rate limit configuration"

# Now rev=2 becomes the default
```

## Step 6: Custom Domain (Placeholder)

### Prerequisites for Custom Domains

- Domain name (e.g., api.contoso.com)
- SSL/TLS certificate (PFX or PEM format)
- DNS access to create CNAME record

### Upload Certificate to Key Vault

```bash
# Upload certificate to Key Vault
az keyvault certificate import \
  --vault-name ${KV_NAME} \
  --name api-contoso-com \
  --file /path/to/certificate.pfx \
  --password "cert-password"

# Get certificate identifier
CERT_ID=$(az keyvault certificate show \
  --vault-name ${KV_NAME} \
  --name api-contoso-com \
  --query id -o tsv)
```

### Configure Custom Domain in APIM

```bash
# Add custom domain (example for gateway endpoint)
# This typically requires Portal or ARM template
# See: https://learn.microsoft.com/azure/api-management/configure-custom-domain

# Via Portal:
# APIM → Custom domains → Gateway → Add
# - Hostname: api.contoso.com
# - Certificate: Select from Key Vault
# - Negotiate client certificate: false

# Update DNS CNAME record:
# api.contoso.com → {apim-name}.azure-api.net
```

## Step 7: Cleanup

Keep resources for Lab 4 or clean up:

```bash
# Delete entire resource group
az group delete --name ${RESOURCE_GROUP} --yes --no-wait

# Or selectively remove resources
az network vnet delete --name ${VNET_NAME} --resource-group ${RESOURCE_GROUP}
az keyvault delete --name ${KV_NAME} --resource-group ${RESOURCE_GROUP}
```

## 🎓 What You Learned

- ✅ Configured VNet integration for internal/private APIM mode
- ✅ Set up private endpoints with Private DNS zones
- ✅ Integrated Azure Key Vault with Managed Identity
- ✅ Created Named Values referencing Key Vault secrets
- ✅ Implemented API versioning with version sets
- ✅ Used revisions for safe, testable deployments
- ✅ Understood custom domain configuration approach

## 📚 Next Steps

Continue to [Lab 4: Expert](../lab-04-expert/README.md) to learn about:
- Self-hosted gateway deployment (Docker + Kubernetes)
- Azure Front Door + APIM integration
- Blue/green deployment with revisions
- Performance optimization and caching strategies

## 📖 Additional Resources

- [VNet Integration](https://learn.microsoft.com/azure/api-management/api-management-using-with-vnet)
- [Private Endpoints](https://learn.microsoft.com/azure/api-management/private-endpoint)
- [Key Vault Integration](https://learn.microsoft.com/azure/api-management/api-management-howto-properties)
- [API Versioning](https://learn.microsoft.com/azure/api-management/api-management-versions)
- [Revisions](https://learn.microsoft.com/azure/api-management/api-management-revisions)
- [Custom Domains](https://learn.microsoft.com/azure/api-management/configure-custom-domain)

## ❓ Troubleshooting

**Issue**: VNet integration fails  
**Solution**: Ensure subnet has /28 or larger address space, NSG rules allow APIM traffic

**Issue**: Private endpoint DNS not resolving  
**Solution**: Verify Private DNS zone is linked to VNet, check DNS zone group configuration

**Issue**: Key Vault access denied  
**Solution**: Confirm Managed Identity is enabled, access policy includes 'get' and 'list' for secrets

**Issue**: Named Value not loading secret  
**Solution**: Check secret identifier format, verify APIM has permissions in Key Vault

**Issue**: Revision not accessible  
**Solution**: Use `;rev=N` syntax in URL, ensure revision was created successfully

---

**Congratulations!** You've mastered advanced APIM networking and security. Ready for Lab 4? 🚀
