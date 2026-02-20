# Lab 6: APIM Workspaces for API Segmentation and Collaboration

**Level**: Intermediate  
**Duration**: 60-90 minutes  
**Prerequisites**: Azure subscription, Azure CLI, completed Lab 1 or existing APIM instance

> **⚠️ Educational Disclaimer**: This repository is provided for educational and learning purposes only. All content, including pricing estimates, tier recommendations, and infrastructure templates, should be validated and adapted for your specific production requirements. Azure API Management features, pricing, and best practices evolve frequently—always consult the <a href="https://learn.microsoft.com/azure/api-management/">official Azure documentation</a> and <a href="https://azure.microsoft.com/pricing/calculator/">Azure Pricing Calculator</a> for the most current information before making production decisions.

## Learning Objectives

By the end of this lab, you will:
- Understand the purpose and benefits of APIM Workspaces
- Configure workspaces for different environments (dev, test, prod)
- Manage APIs within dedicated workspaces
- Implement workspace-based collaboration patterns
- Apply workspace-specific policies and configurations

## What are APIM Workspaces?

APIM Workspaces enable segmentation and isolation of APIs within a single APIM instance. They provide:

### Key Benefits
- **Environment Segmentation**: Separate development, testing, and production APIs
- **Team Collaboration**: Dedicated workspaces for different teams or projects
- **Resource Isolation**: Isolated configurations, policies, and subscriptions per workspace
- **Cost Efficiency**: Share a single APIM instance across multiple environments
- **Simplified Management**: Centralized governance with workspace-level autonomy

### Use Cases
1. **Multi-Environment Deployment**: Dev, test, staging, and prod in one instance
2. **Multi-Tenant Scenarios**: Separate workspaces for different customers or departments
3. **Project Isolation**: Dedicated workspaces for different products or services
4. **Development Workflow**: Isolated environments for feature development and testing

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│              Azure API Management Instance                   │
│                                                              │
│  ┌──────────────────┐  ┌──────────────────┐  ┌────────────┐ │
│  │  Dev Workspace   │  │  Test Workspace  │  │   Prod     │ │
│  │                  │  │                  │  │ Workspace  │ │
│  │  ├─ API v1      │  │  ├─ API v1      │  │ ├─ API v1  │ │
│  │  ├─ API v2      │  │  ├─ API v2      │  │ ├─ API v2  │ │
│  │  └─ Policies    │  │  └─ Policies    │  │ └─ Policies│ │
│  └──────────────────┘  └──────────────────┘  └────────────┘ │
│                                                              │
│  Shared: Gateway URL, Publisher, Diagnostics                 │
└─────────────────────────────────────────────────────────────┘
          ↓                    ↓                    ↓
    Dev Backend          Test Backend          Prod Backend
```

## Prerequisites

### Required Tools
- Azure subscription ([free account](https://azure.microsoft.com/free/))
- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli) (version 2.40+)
- [Git](https://git-scm.com/downloads)
- Text editor (VS Code recommended)

### Existing Resources
You need either:
- **Option A**: An existing APIM instance (from Lab 1 or previous deployment)
- **Option B**: Deploy a new instance (see Step 1)

### Supported SKUs
APIM Workspaces are available in:
- **Developer tier**: For development and testing
- **Basic, Standard, Premium tiers**: For production workloads
- **Basic v2, Standard v2 tiers**: Modern consumption-based tiers

> **Note**: Consumption tier does **not** support workspaces.

## Step 1: Deploy APIM Instance (Optional)

If you don't have an existing APIM instance, deploy one now.

### Option A: Using Bicep with Workspaces

```bash
# Clone this repository
git clone https://github.com/jonathandhaene/apim-educational.git
cd apim-educational/infra/bicep

# Login to Azure
az login
az account set --subscription "<your-subscription-id>"

# Create resource group
az group create --name rg-apim-workspaces-lab --location eastus

# Deploy APIM with workspaces
az deployment group create \
  --resource-group rg-apim-workspaces-lab \
  --template-file main.bicep \
  --parameters \
    environment=dev \
    baseName=apim-ws-lab \
    apimSku=Developer \
    publisherEmail=admin@contoso.com \
    publisherName="Contoso Labs" \
    enableWorkspaces=true \
    workspaceConfigs='[
      {
        "name": "dev",
        "displayName": "Development Workspace",
        "description": "Workspace for development and experimentation"
      },
      {
        "name": "test",
        "displayName": "Testing Workspace",
        "description": "Workspace for QA and integration testing"
      },
      {
        "name": "prod",
        "displayName": "Production Workspace",
        "description": "Workspace for production APIs"
      }
    ]'

# Note: Deployment takes 30-45 minutes for classic tiers or 5-15 minutes for v2 tiers
```

### Option B: Using Terraform with Workspaces

```bash
cd apim-educational/infra/terraform

# Initialize Terraform
terraform init

# Create terraform.tfvars file
cat > terraform.tfvars <<EOF
resource_group_name = "rg-apim-workspaces-lab"
location           = "eastus"
apim_name          = "apim-ws-lab-yourname"
apim_sku          = "Developer"
apim_capacity     = 1
publisher_email   = "admin@contoso.com"
publisher_name    = "Contoso Labs"

# Workspace configuration
workspaces = {
  dev = {
    display_name = "Development Workspace"
    description  = "Workspace for development and experimentation"
  }
  test = {
    display_name = "Testing Workspace"
    description  = "Workspace for QA and integration testing"
  }
  prod = {
    display_name = "Production Workspace"
    description  = "Workspace for production APIs"
  }
}

tags = {
  Environment = "lab"
  Purpose     = "workspace-demo"
}
EOF

# Deploy
terraform plan
terraform apply
```

### Option C: Using Azure Portal

1. Navigate to [Azure Portal](https://portal.azure.com)
2. Create API Management instance with Developer tier
3. After deployment, we'll add workspaces via CLI (Step 2)

## Step 2: Create Workspaces via Azure CLI

If you deployed APIM without workspaces, add them now:

```bash
# Set variables
RESOURCE_GROUP="rg-apim-workspaces-lab"
APIM_NAME="apim-ws-lab-yourname"

# Create dev workspace
az rest \
  --method put \
  --url "https://management.azure.com/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/workspaces/dev?api-version=2023-09-01-preview" \
  --body '{
    "properties": {
      "displayName": "Development Workspace",
      "description": "Workspace for development and experimentation"
    }
  }'

# Create test workspace
az rest \
  --method put \
  --url "https://management.azure.com/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/workspaces/test?api-version=2023-09-01-preview" \
  --body '{
    "properties": {
      "displayName": "Testing Workspace",
      "description": "Workspace for QA and integration testing"
    }
  }'

# Create prod workspace
az rest \
  --method put \
  --url "https://management.azure.com/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/workspaces/prod?api-version=2023-09-01-preview" \
  --body '{
    "properties": {
      "displayName": "Production Workspace",
      "description": "Workspace for production APIs"
    }
  }'

# List all workspaces
az rest \
  --method get \
  --url "https://management.azure.com/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/workspaces?api-version=2023-09-01-preview" \
  | jq -r '.value[] | "\(.name): \(.properties.displayName)"'
```

## Step 3: Configure APIs in Workspaces

Now we'll import and configure APIs within each workspace.

### Create Sample API Specification

First, create a sample OpenAPI spec for testing:

```bash
# Create sample OpenAPI spec
cat > /tmp/sample-api.json <<'EOF'
{
  "openapi": "3.0.0",
  "info": {
    "title": "Sample API",
    "version": "1.0.0",
    "description": "A sample API for workspace demonstration"
  },
  "servers": [
    {
      "url": "https://jsonplaceholder.typicode.com"
    }
  ],
  "paths": {
    "/posts": {
      "get": {
        "summary": "Get all posts",
        "operationId": "getPosts",
        "tags": ["posts"],
        "responses": {
          "200": {
            "description": "List of posts"
          }
        }
      }
    },
    "/posts/{id}": {
      "get": {
        "summary": "Get post by ID",
        "operationId": "getPostById",
        "tags": ["posts"],
        "parameters": [
          {
            "name": "id",
            "in": "path",
            "required": true,
            "schema": {
              "type": "integer"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Post details"
          }
        }
      }
    }
  }
}
EOF
```

### Import API into Dev Workspace

```bash
# Import API to dev workspace
az rest \
  --method put \
  --url "https://management.azure.com/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/workspaces/dev/apis/sample-api?api-version=2023-09-01-preview" \
  --body '{
    "properties": {
      "displayName": "Sample API - Dev",
      "path": "dev/sample",
      "protocols": ["https"],
      "serviceUrl": "https://jsonplaceholder.typicode.com",
      "format": "openapi+json",
      "value": "'"$(cat /tmp/sample-api.json | jq -c .)"'"
    }
  }'
```

### Import API into Test Workspace

```bash
# Import API to test workspace with different path
az rest \
  --method put \
  --url "https://management.azure.com/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/workspaces/test/apis/sample-api?api-version=2023-09-01-preview" \
  --body '{
    "properties": {
      "displayName": "Sample API - Test",
      "path": "test/sample",
      "protocols": ["https"],
      "serviceUrl": "https://jsonplaceholder.typicode.com"
    }
  }'
```

### Import API into Prod Workspace

```bash
# Import API to prod workspace
az rest \
  --method put \
  --url "https://management.azure.com/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/workspaces/prod/apis/sample-api?api-version=2023-09-01-preview" \
  --body '{
    "properties": {
      "displayName": "Sample API - Production",
      "path": "prod/sample",
      "protocols": ["https"],
      "serviceUrl": "https://jsonplaceholder.typicode.com"
    }
  }'
```

## Step 4: Apply Workspace-Specific Policies

Different workspaces often require different policies. Let's configure environment-specific policies.

### Dev Workspace - Permissive Policy (No Rate Limiting)

```bash
# Apply permissive policy to dev workspace API
az rest \
  --method put \
  --url "https://management.azure.com/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/workspaces/dev/apis/sample-api/policies/policy?api-version=2023-09-01-preview" \
  --body '{
    "properties": {
      "value": "<policies><inbound><base /><set-header name=\"X-Environment\" exists-action=\"override\"><value>development</value></set-header><cors><allowed-origins><origin>*</origin></allowed-origins><allowed-methods><method>*</method></allowed-methods></cors></inbound><backend><base /></backend><outbound><base /></outbound><on-error><base /></on-error></policies>",
      "format": "xml"
    }
  }'
```

### Test Workspace - Moderate Rate Limiting

```bash
# Apply moderate rate limiting to test workspace
az rest \
  --method put \
  --url "https://management.azure.com/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/workspaces/test/apis/sample-api/policies/policy?api-version=2023-09-01-preview" \
  --body '{
    "properties": {
      "value": "<policies><inbound><base /><rate-limit calls=\"100\" renewal-period=\"60\" /><set-header name=\"X-Environment\" exists-action=\"override\"><value>test</value></set-header></inbound><backend><base /></backend><outbound><base /></outbound><on-error><base /></on-error></policies>",
      "format": "xml"
    }
  }'
```

### Prod Workspace - Strict Rate Limiting & Caching

```bash
# Apply strict policies to prod workspace
az rest \
  --method put \
  --url "https://management.azure.com/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/workspaces/prod/apis/sample-api/policies/policy?api-version=2023-09-01-preview" \
  --body '{
    "properties": {
      "value": "<policies><inbound><base /><rate-limit calls=\"50\" renewal-period=\"60\" /><quota calls=\"10000\" renewal-period=\"86400\" /><cache-lookup vary-by-developer=\"false\" vary-by-developer-groups=\"false\" /><set-header name=\"X-Environment\" exists-action=\"override\"><value>production</value></set-header></inbound><backend><base /></backend><outbound><cache-store duration=\"300\" /><base /></outbound><on-error><base /></on-error></policies>",
      "format": "xml"
    }
  }'
```

## Step 5: Test Workspace APIs

Now let's test the APIs in each workspace.

### Get APIM Gateway URL

```bash
GATEWAY_URL=$(az apim show \
  --resource-group ${RESOURCE_GROUP} \
  --name ${APIM_NAME} \
  --query gatewayUrl -o tsv)

echo "Gateway URL: ${GATEWAY_URL}"
```

### Get Subscription Key

```bash
# Get subscription key (built-in all-access)
SUBSCRIPTION_KEY=$(az rest \
  --method post \
  --url "https://management.azure.com/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/subscriptions/master/listSecrets?api-version=2022-08-01" \
  | jq -r .primaryKey)

echo "Subscription Key: ${SUBSCRIPTION_KEY}"
```

### Test Dev Workspace API

```bash
# Test dev workspace (no rate limiting)
curl "${GATEWAY_URL}/dev/sample/posts/1" \
  -H "Ocp-Apim-Subscription-Key: ${SUBSCRIPTION_KEY}" \
  -v

# Should see X-Environment: development header in response
```

### Test Test Workspace API

```bash
# Test test workspace (moderate rate limiting)
curl "${GATEWAY_URL}/test/sample/posts/1" \
  -H "Ocp-Apim-Subscription-Key: ${SUBSCRIPTION_KEY}" \
  -v

# Should see X-Environment: test header
# Try 101 requests quickly - should get rate limited
for i in {1..101}; do
  curl -s "${GATEWAY_URL}/test/sample/posts/1" \
    -H "Ocp-Apim-Subscription-Key: ${SUBSCRIPTION_KEY}" \
    -o /dev/null -w "%{http_code}\n"
done
```

### Test Prod Workspace API

```bash
# Test prod workspace (strict rate limiting + caching)
curl "${GATEWAY_URL}/prod/sample/posts/1" \
  -H "Ocp-Apim-Subscription-Key: ${SUBSCRIPTION_KEY}" \
  -v

# Should see X-Environment: production header
# Second request should be served from cache (faster)
time curl "${GATEWAY_URL}/prod/sample/posts/1" \
  -H "Ocp-Apim-Subscription-Key: ${SUBSCRIPTION_KEY}"
```

## Step 6: Workspace Management Best Practices

### 1. Naming Conventions

Use consistent naming across workspaces:

```
workspace-name: <environment>
  - dev, test, staging, prod
  - OR team-based: team-a, team-b
  - OR project-based: project-alpha, project-beta

API paths:
  - <workspace>/<api-name>/<version>
  - Example: dev/orders/v1, prod/orders/v1
```

### 2. Policy Inheritance

Structure policies hierarchically:

```
Global Policies (APIM level)
  └─> Workspace Policies
      └─> API Policies
          └─> Operation Policies
```

### 3. Subscription Management

Create workspace-specific subscriptions:

```bash
# Create dev workspace subscription
az rest \
  --method put \
  --url "https://management.azure.com/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/workspaces/dev/subscriptions/dev-team?api-version=2023-09-01-preview" \
  --body '{
    "properties": {
      "displayName": "Dev Team Subscription",
      "scope": "/workspaces/dev",
      "state": "active"
    }
  }'
```

### 4. Access Control

Implement RBAC per workspace:

```bash
# Assign contributor role to dev workspace
WORKSPACE_ID="/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/workspaces/dev"

az role assignment create \
  --assignee user@example.com \
  --role "API Management Service Contributor" \
  --scope "${WORKSPACE_ID}"
```

## Step 7: Monitor Workspace Activity

### View Workspace APIs

```bash
# List all APIs in dev workspace
az rest \
  --method get \
  --url "https://management.azure.com/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/workspaces/dev/apis?api-version=2023-09-01-preview" \
  | jq -r '.value[] | "\(.name): \(.properties.displayName) - \(.properties.path)"'
```

### Export Workspace Configuration

```bash
# Export workspace configuration for backup/migration
az rest \
  --method get \
  --url "https://management.azure.com/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/workspaces/dev?api-version=2023-09-01-preview" \
  > /tmp/dev-workspace-config.json

cat /tmp/dev-workspace-config.json | jq .
```

## Common Use Case: Promotion Workflow

Implement a promotion workflow from dev → test → prod:

### 1. Develop in Dev Workspace

```bash
# Create and test API in dev workspace
# Iterate on policies and configurations
```

### 2. Promote to Test Workspace

```bash
# Export API from dev
DEV_API=$(az rest \
  --method get \
  --url "https://management.azure.com/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/workspaces/dev/apis/sample-api?api-version=2023-09-01-preview&export=true")

# Import to test workspace
echo "$DEV_API" | jq '.properties.path = "test/sample"' | \
az rest \
  --method put \
  --url "https://management.azure.com/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/workspaces/test/apis/sample-api?api-version=2023-09-01-preview" \
  --body @-
```

### 3. Validate in Test Workspace

```bash
# Run integration tests against test workspace
# Validate with QA team
```

### 4. Promote to Prod Workspace

```bash
# After validation, promote to prod
# Similar export/import process as above
```

## Cleanup

When finished with the lab, clean up resources to avoid charges:

```bash
# Delete the entire resource group
az group delete --name rg-apim-workspaces-lab --yes --no-wait
```

Or keep APIM but remove workspaces:

```bash
# Delete individual workspaces
az rest \
  --method delete \
  --url "https://management.azure.com/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/workspaces/dev?api-version=2023-09-01-preview"

az rest \
  --method delete \
  --url "https://management.azure.com/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/workspaces/test?api-version=2023-09-01-preview"

az rest \
  --method delete \
  --url "https://management.azure.com/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/workspaces/prod?api-version=2023-09-01-preview"
```

## Key Takeaways

✅ **Workspaces enable efficient multi-environment management** within a single APIM instance  
✅ **Cost optimization** by sharing infrastructure across environments  
✅ **Isolated configurations** allow environment-specific policies and settings  
✅ **Simplified promotion workflows** from dev to prod  
✅ **Team collaboration** through dedicated workspace access control

## Next Steps

- Explore [Lab 5: Operations & Architecture](../lab-05-ops-architecture/README.md) for production readiness
- Read [Workspaces Best Practices](../../docs/workspaces.md)
- Review [APIM Security Guide](../../docs/security.md)
- Learn about [API Versioning and Revisions](../lab-03-advanced/README.md)

## Additional Resources

- [Azure APIM Workspaces Documentation](https://learn.microsoft.com/azure/api-management/workspaces-overview)
- [APIM REST API Reference](https://learn.microsoft.com/rest/api/apimanagement/)
- [Workspace RBAC Roles](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#api-management)

## Troubleshooting

### Workspace creation fails with 404

**Issue**: REST API returns 404 when creating workspace  
**Solution**: Ensure you're using API version `2023-09-01-preview` or later

### Cannot access workspace APIs

**Issue**: 404 when calling workspace API paths  
**Solution**: Verify the API path includes workspace prefix (e.g., `/dev/sample/posts`)

### Policies not applying

**Issue**: Workspace policies not taking effect  
**Solution**: Check policy inheritance order; workspace policies may be overridden by API-level policies

---

**Congratulations!** 🎉 You've successfully set up and managed APIM Workspaces for multi-environment API deployment!
