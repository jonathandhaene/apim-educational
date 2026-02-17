# Azure API Management Workspaces

This guide provides comprehensive documentation on APIM Workspaces, including their purpose, benefits, architecture patterns, and best practices for implementation.

> **⚠️ Educational Disclaimer**: This documentation is provided for educational purposes. Always verify current Azure APIM features, limitations, and pricing in the [official Azure documentation](https://learn.microsoft.com/azure/api-management/) before production implementation.

## Table of Contents
- [What are APIM Workspaces?](#what-are-apim-workspaces)
- [Key Benefits](#key-benefits)
- [Architecture Patterns](#architecture-patterns)
- [Use Cases](#use-cases)
- [Implementation Guide](#implementation-guide)
- [Best Practices](#best-practices)
- [Security Considerations](#security-considerations)
- [Monitoring and Operations](#monitoring-and-operations)
- [Limitations and Constraints](#limitations-and-constraints)

## What are APIM Workspaces?

APIM Workspaces are logical containers within a single API Management instance that enable segmentation, isolation, and collaborative management of APIs. Think of workspaces as separate environments or projects that share the same underlying APIM infrastructure but maintain independent configurations and policies.

### Core Concepts

**Workspace**: A logical boundary within APIM that contains:
- APIs and their operations
- Products and subscriptions
- Policies (API-level and operation-level)
- Named values and backend configurations
- Diagnostic settings

**Shared Resources**: Elements that exist at the APIM instance level:
- Gateway infrastructure and URL
- Publisher information
- Global policies
- System-level diagnostics
- Network configuration (VNet, private endpoints)

### Feature Availability

| Feature | Workspace-Scoped | Instance-Scoped |
|---------|------------------|-----------------|
| APIs | ✅ | ✅ |
| Products | ✅ | ✅ |
| Subscriptions | ✅ | ✅ |
| Policies | ✅ | ✅ |
| Named Values | ✅ | ✅ |
| Backends | ✅ | ✅ |
| Certificates | ❌ | ✅ |
| Users & Groups | ❌ | ✅ |
| Developer Portal | ❌ | ✅ |
| Gateway URL | ❌ | ✅ |

## Key Benefits

### 1. Environment Segmentation

Maintain multiple environments (dev, test, staging, prod) within a single APIM instance:

**Cost Efficiency**
- Single APIM instance serves multiple environments
- Reduced infrastructure overhead
- Shared capacity across workspaces

**Example**: Instead of deploying 3 separate APIM instances ($150/month × 3), use one instance with 3 workspaces ($150/month).

### 2. Team Collaboration

Enable parallel development across teams:

**Isolation**
- Teams work in dedicated workspaces without interference
- Independent API versioning and policies
- Workspace-specific RBAC controls

**Example**: Frontend team manages APIs in `frontend-workspace`, Backend team in `backend-workspace`.

### 3. Multi-Tenant Scenarios

Support multiple customers or business units:

**Resource Separation**
- Dedicated workspaces per tenant
- Isolated configurations and data
- Custom policies per tenant

**Example**: SaaS provider manages `customer-a-workspace`, `customer-b-workspace` with tenant-specific configurations.

### 4. Simplified Promotion Workflows

Streamline API promotion from development to production:

**Controlled Progression**
- Dev → Test → Staging → Prod workflow
- API export/import between workspaces
- Policy validation at each stage

## Architecture Patterns

### Pattern 1: Environment-Based Segmentation

Most common pattern for managing API lifecycle stages.

```
┌─────────────────────────────────────────────────────┐
│         Azure API Management Instance               │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────┐│
│  │     Dev      │  │     Test     │  │    Prod    ││
│  │  Workspace   │  │  Workspace   │  │ Workspace  ││
│  │              │  │              │  │            ││
│  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌────────┐││
│  │ │ API v1   │ │  │ │ API v1   │ │  │ │API v1  │││
│  │ │ API v2   │ │  │ │ API v2   │ │  │ │API v2  │││
│  │ └──────────┘ │  │ └──────────┘ │  │ └────────┘││
│  │              │  │              │  │            ││
│  │ Policies:    │  │ Policies:    │  │ Policies:  ││
│  │ - Permissive │  │ - Moderate   │  │ - Strict   ││
│  │ - Debug logs │  │ - Validation │  │ - Caching  ││
│  └──────────────┘  └──────────────┘  └────────────┘│
└─────────────────────────────────────────────────────┘
      ↓                   ↓                   ↓
  Dev Backend       Test Backend         Prod Backend
```

**Configuration**:
```hcl
# Terraform example
workspaces = {
  dev = {
    display_name = "Development"
    description  = "APIs under active development"
  }
  test = {
    display_name = "Testing"
    description  = "QA and integration testing"
  }
  staging = {
    display_name = "Staging"
    description  = "Pre-production validation"
  }
  prod = {
    display_name = "Production"
    description  = "Production APIs"
  }
}
```

### Pattern 2: Team-Based Segmentation

Organize workspaces by development teams or business units.

```
┌─────────────────────────────────────────────────────┐
│         Azure API Management Instance               │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────┐│
│  │  Frontend    │  │   Backend    │  │   Mobile   ││
│  │   Workspace  │  │  Workspace   │  │ Workspace  ││
│  │              │  │              │  │            ││
│  │ Web APIs     │  │ Services     │  │  App APIs  ││
│  │ SPA APIs     │  │ Microservices│  │  SDK APIs  ││
│  └──────────────┘  └──────────────┘  └────────────┘│
└─────────────────────────────────────────────────────┘
```

### Pattern 3: Multi-Tenant Segmentation

Isolate APIs for different customers or organizations.

```
┌─────────────────────────────────────────────────────┐
│         Azure API Management Instance (SaaS)        │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────┐│
│  │  Customer A  │  │  Customer B  │  │ Customer C ││
│  │  Workspace   │  │  Workspace   │  │ Workspace  ││
│  │              │  │              │  │            ││
│  │ Custom APIs  │  │ Custom APIs  │  │Custom APIs ││
│  │ Custom Limits│  │ Custom Limits│  │Custom Limit││
│  └──────────────┘  └──────────────┘  └────────────┘│
└─────────────────────────────────────────────────────┘
```

### Pattern 4: Hybrid - Combined Segmentation

Combine multiple patterns for complex scenarios.

```
┌─────────────────────────────────────────────────────────┐
│         Azure API Management Instance                   │
│  ┌─────────────────────┐  ┌──────────────────────────┐ │
│  │   Team A            │  │   Team B                 │ │
│  │  ┌─────┐  ┌──────┐  │  │  ┌─────┐  ┌──────┐      │ │
│  │  │ Dev │  │ Prod │  │  │  │ Dev │  │ Prod │      │ │
│  │  └─────┘  └──────┘  │  │  └─────┘  └──────┘      │ │
│  └─────────────────────┘  └──────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

## Use Cases

### Use Case 1: Multi-Stage Deployment Pipeline

**Scenario**: Organization needs to test APIs before production deployment.

**Implementation**:
1. **Dev Workspace**: Developers create and test new APIs
2. **Test Workspace**: QA team runs automated tests
3. **Staging Workspace**: Pre-production validation with production-like data
4. **Prod Workspace**: Live customer-facing APIs

**Benefits**:
- Controlled promotion workflow
- Environment-specific policies (dev: no rate limiting, prod: strict limits)
- Isolated testing without affecting production

### Use Case 2: API Versioning and Migration

**Scenario**: Migrating from API v1 to v2 while supporting both versions.

**Implementation**:
1. **v1-workspace**: Existing API v1 for legacy clients
2. **v2-workspace**: New API v2 for new clients
3. Gradual client migration from v1 to v2
4. Deprecate v1 workspace after full migration

**Benefits**:
- Parallel version support
- Independent policy management
- Clean separation during migration

### Use Case 3: Multi-Region API Management

**Scenario**: Global organization with regional API requirements.

**Implementation**:
1. **us-workspace**: APIs for US region with US-specific backends
2. **eu-workspace**: APIs for EU region with GDPR-compliant backends
3. **asia-workspace**: APIs for Asia-Pacific region

**Benefits**:
- Regional compliance (GDPR, data residency)
- Optimized routing to regional backends
- Region-specific policies

### Use Case 4: Partner API Program

**Scenario**: Providing APIs to multiple partner organizations.

**Implementation**:
1. **partner-a-workspace**: Custom APIs for Partner A
2. **partner-b-workspace**: Custom APIs for Partner B
3. Shared core APIs at instance level

**Benefits**:
- Partner-specific customization
- Independent subscription management
- Isolated metrics and analytics

## Implementation Guide

### Prerequisites

**Supported SKUs**:
- ✅ Developer (for dev/test)
- ✅ Basic, Standard, Premium (production)
- ✅ Basic v2, Standard v2 (modern consumption-based)
- ❌ Consumption (not supported)

**Required Permissions**:
- `Microsoft.ApiManagement/service/workspaces/write`
- `Microsoft.ApiManagement/service/workspaces/read`

### Terraform Implementation

```hcl
# Define workspace configuration
variable "workspaces" {
  type = map(object({
    display_name = string
    description  = string
  }))
  default = {
    dev = {
      display_name = "Development Workspace"
      description  = "APIs under active development"
    }
    test = {
      display_name = "Testing Workspace"
      description  = "QA and integration testing"
    }
    prod = {
      display_name = "Production Workspace"
      description  = "Production-ready APIs"
    }
  }
}

# Create workspaces
resource "azurerm_api_management_workspace" "workspaces" {
  for_each = var.workspaces

  name                = each.key
  api_management_name = azurerm_api_management.main.name
  resource_group_name = var.resource_group_name
  display_name        = each.value.display_name
  description         = each.value.description
}

# Output workspace IDs
output "workspace_ids" {
  value = { for k, v in azurerm_api_management_workspace.workspaces : k => v.id }
}
```

### Bicep Implementation

```bicep
// Workspace configurations parameter
@description('Workspace configurations')
param workspaceConfigs array = [
  {
    name: 'dev'
    displayName: 'Development Workspace'
    description: 'APIs under active development'
  }
  {
    name: 'test'
    displayName: 'Testing Workspace'
    description: 'QA and integration testing'
  }
  {
    name: 'prod'
    displayName: 'Production Workspace'
    description: 'Production-ready APIs'
  }
]

// APIM instance reference
resource apim 'Microsoft.ApiManagement/service@2023-09-01-preview' existing = {
  name: apimName
}

// Create workspaces
resource workspace 'Microsoft.ApiManagement/service/workspaces@2023-09-01-preview' = [for ws in workspaceConfigs: {
  parent: apim
  name: ws.name
  properties: {
    displayName: ws.displayName
    description: ws.description
  }
}]

// Outputs
output workspaceIds array = [for i in range(0, length(workspaceConfigs)): workspace[i].id]
```

### Azure CLI Implementation

```bash
# Variables
RESOURCE_GROUP="rg-apim"
APIM_NAME="apim-instance"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Create workspace function
create_workspace() {
  local name=$1
  local display_name=$2
  local description=$3
  
  az rest \
    --method put \
    --url "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/workspaces/${name}?api-version=2023-09-01-preview" \
    --body "{
      \"properties\": {
        \"displayName\": \"${display_name}\",
        \"description\": \"${description}\"
      }
    }"
}

# Create workspaces
create_workspace "dev" "Development" "APIs under development"
create_workspace "test" "Testing" "QA and testing"
create_workspace "prod" "Production" "Production APIs"
```

## Best Practices

### 1. Naming Conventions

**Workspace Names**:
```
✅ Good:
  - dev, test, staging, prod (environment-based)
  - team-frontend, team-backend (team-based)
  - customer-acme, customer-contoso (tenant-based)

❌ Avoid:
  - workspace1, workspace2 (non-descriptive)
  - dev-2024-01-15 (date-based, hard to maintain)
```

**API Path Structure**:
```
Format: /<workspace>/<api>/<version>/<operation>

Examples:
  - /dev/orders/v1/create
  - /test/customers/v2/list
  - /prod/inventory/v1/search
```

### 2. Policy Management Strategy

**Hierarchy**: Global → Workspace → API → Operation

```xml
<!-- Global Policy (All workspaces) -->
<policies>
  <inbound>
    <cors>
      <allowed-origins><origin>*</origin></allowed-origins>
    </cors>
  </inbound>
</policies>

<!-- Dev Workspace Policy -->
<policies>
  <inbound>
    <base /> <!-- Inherit global -->
    <set-header name="X-Environment" exists-action="override">
      <value>development</value>
    </set-header>
  </inbound>
</policies>

<!-- Test Workspace Policy -->
<policies>
  <inbound>
    <base />
    <rate-limit calls="100" renewal-period="60" />
    <set-header name="X-Environment" exists-action="override">
      <value>test</value>
    </set-header>
  </inbound>
</policies>

<!-- Prod Workspace Policy -->
<policies>
  <inbound>
    <base />
    <rate-limit calls="50" renewal-period="60" />
    <quota calls="10000" renewal-period="86400" />
    <cache-lookup vary-by-developer="false" />
    <set-header name="X-Environment" exists-action="override">
      <value>production</value>
    </set-header>
  </inbound>
  <outbound>
    <cache-store duration="300" />
    <base />
  </outbound>
</policies>
```

### 3. Subscription Management

**Workspace-Scoped Subscriptions**:

```bash
# Create workspace-specific subscription
az rest \
  --method put \
  --url "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/workspaces/dev/subscriptions/dev-team?api-version=2023-09-01-preview" \
  --body '{
    "properties": {
      "displayName": "Dev Team Subscription",
      "scope": "/workspaces/dev",
      "state": "active"
    }
  }'
```

**Best Practices**:
- Create dedicated subscriptions per workspace
- Use descriptive names (e.g., `dev-frontend-team`, `test-qa-team`)
- Implement subscription key rotation policies
- Monitor subscription usage per workspace

### 4. RBAC and Access Control

**Workspace-Level Permissions**:

```bash
# Assign workspace-level access
WORKSPACE_ID="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/workspaces/dev"

# Developer access (read-only)
az role assignment create \
  --assignee developer@contoso.com \
  --role "API Management Service Reader" \
  --scope "${WORKSPACE_ID}"

# Team lead access (read-write)
az role assignment create \
  --assignee lead@contoso.com \
  --role "API Management Service Contributor" \
  --scope "${WORKSPACE_ID}"
```

**Recommended Roles**:
- **Developers**: Reader (view APIs, test in portal)
- **Team Leads**: Contributor (manage APIs, policies)
- **Admins**: Owner (full workspace management)

### 5. Promotion Workflow

Implement structured promotion process:

```bash
#!/bin/bash
# promote-api.sh - Promote API between workspaces

SOURCE_WORKSPACE=$1  # e.g., "dev"
TARGET_WORKSPACE=$2  # e.g., "test"
API_NAME=$3

# 1. Export API from source workspace
API_CONFIG=$(az rest \
  --method get \
  --url "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/workspaces/${SOURCE_WORKSPACE}/apis/${API_NAME}?api-version=2023-09-01-preview&export=true")

# 2. Update path for target workspace
UPDATED_CONFIG=$(echo "$API_CONFIG" | jq ".properties.path = \"${TARGET_WORKSPACE}/$(echo "$API_CONFIG" | jq -r .properties.path | cut -d/ -f2-)\"")

# 3. Import to target workspace
echo "$UPDATED_CONFIG" | az rest \
  --method put \
  --url "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/workspaces/${TARGET_WORKSPACE}/apis/${API_NAME}?api-version=2023-09-01-preview" \
  --body @-

echo "✅ API ${API_NAME} promoted from ${SOURCE_WORKSPACE} to ${TARGET_WORKSPACE}"
```

### 6. Monitoring and Observability

**Workspace-Specific Metrics**:

```kusto
// KQL query for workspace API calls
ApiManagementGatewayLogs
| where TimeGenerated > ago(1h)
| where Url contains "/dev/" or Url contains "/test/" or Url contains "/prod/"
| extend Workspace = case(
    Url contains "/dev/", "dev",
    Url contains "/test/", "test",
    Url contains "/prod/", "prod",
    "unknown"
  )
| summarize Count=count(), AvgDuration=avg(BackendResponseTime) by Workspace, bin(TimeGenerated, 5m)
| render timechart
```

## Security Considerations

### 1. Workspace Isolation

**Network Isolation**: Workspaces share the same gateway and network configuration. Use policies for logical isolation:

```xml
<!-- Dev workspace - Allow all origins -->
<policies>
  <inbound>
    <cors>
      <allowed-origins><origin>*</origin></allowed-origins>
    </cors>
  </inbound>
</policies>

<!-- Prod workspace - Restrict origins -->
<policies>
  <inbound>
    <cors>
      <allowed-origins>
        <origin>https://app.contoso.com</origin>
      </allowed-origins>
    </cors>
    <ip-filter action="allow">
      <address-range from="10.0.0.0" to="10.0.255.255" />
    </ip-filter>
  </inbound>
</policies>
```

### 2. Secrets Management

**Named Values**: Use workspace-scoped named values for environment-specific secrets:

```bash
# Create workspace-specific secret
az rest \
  --method put \
  --url "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/workspaces/prod/namedValues/backend-api-key?api-version=2023-09-01-preview" \
  --body '{
    "properties": {
      "displayName": "backend-api-key",
      "value": "secret-value-here",
      "secret": true,
      "keyVault": {
        "secretIdentifier": "https://keyvault.vault.azure.net/secrets/backend-key"
      }
    }
  }'
```

### 3. Authentication and Authorization

**Workspace-Level JWT Validation**:

```xml
<policies>
  <inbound>
    <validate-jwt header-name="Authorization" failed-validation-httpcode="401">
      <openid-config url="https://login.microsoftonline.com/{tenant}/.well-known/openid-configuration" />
      <audiences>
        <audience>api://dev-workspace-api</audience>
      </audiences>
      <required-claims>
        <claim name="workspace" match="all">
          <value>dev</value>
        </claim>
      </required-claims>
    </validate-jwt>
  </inbound>
</policies>
```

## Monitoring and Operations

### Workspace Metrics

**Key Performance Indicators**:
- API call count per workspace
- Average response time per workspace
- Error rate per workspace
- Subscription usage per workspace

**Application Insights Query**:

```kusto
// Workspace performance comparison
requests
| where cloud_RoleName == "APIManagement"
| extend Workspace = extract(@"/(\w+)/", 1, url)
| summarize 
    Requests = count(),
    AvgDuration = avg(duration),
    P95Duration = percentile(duration, 95),
    ErrorRate = countif(success == false) * 100.0 / count()
  by Workspace, bin(timestamp, 1h)
| order by timestamp desc
```

### Operational Procedures

**Daily Operations**:
1. Monitor workspace API health
2. Review error rates per workspace
3. Check subscription usage limits
4. Validate policy effectiveness

**Weekly Operations**:
1. Review workspace resource utilization
2. Audit RBAC assignments
3. Update workspace policies as needed
4. Plan API promotions

**Monthly Operations**:
1. Workspace capacity planning
2. Cost analysis per workspace
3. Security audit
4. Documentation updates

## Limitations and Constraints

### Current Limitations

**Workspace-Level Restrictions**:
- ❌ Certificates are instance-level only (cannot be workspace-scoped)
- ❌ Developer portal is shared across workspaces
- ❌ Users and groups are instance-level only
- ❌ Custom domains apply to entire instance
- ❌ Gateway URL is shared

**API Version**:
- Requires API version `2023-09-01-preview` or later
- Some features may be in preview

**SKU Limitations**:
- Not available in Consumption tier
- Workspace count may be limited by SKU (check documentation)

### Workarounds

**Certificate Management**:
```xml
<!-- Use workspace-specific named values for certificate selection -->
<policies>
  <inbound>
    <authentication-certificate certificate-id="{{workspace-cert-id}}" />
  </inbound>
</policies>
```

**Developer Portal**:
- Use API grouping and tagging to organize workspace APIs
- Implement custom portal with workspace filtering

### Scaling Considerations

**Performance Impact**:
- Workspaces share gateway capacity
- Monitor overall instance capacity
- Consider Premium tier for multi-region if needed

**Limits**:
- Check current workspace limits in Azure documentation
- Plan workspace structure to stay within limits
- Consider multiple APIM instances for very large deployments

## Cost Optimization

### Workspace vs. Multiple Instances

**Scenario: 3 Environments (Dev, Test, Prod)**

**Option 1: Separate APIM Instances**
```
Dev APIM:   $50/month (Developer tier)
Test APIM:  $50/month (Developer tier)
Prod APIM:  $2,800/month (Premium tier)
Total:      $2,900/month
```

**Option 2: Single APIM with Workspaces**
```
APIM:       $2,800/month (Premium tier, 3 workspaces)
Total:      $2,800/month
Savings:    $100/month (3.4%)
```

**Additional Savings**:
- Reduced management overhead
- Shared diagnostics and monitoring
- Simplified network configuration

### Cost Allocation

**Tag-Based Tracking**:
```hcl
resource "azurerm_api_management_workspace" "workspaces" {
  for_each = var.workspaces
  # Workspaces inherit APIM tags - use custom tracking for workspace costs
  # Implement Azure Cost Management tags at API/subscription level
}
```

## Migration Strategies

### Migrating to Workspaces

**From Multiple APIM Instances**:

1. **Assessment**:
   - Inventory APIs across instances
   - Identify shared policies and configurations
   - Plan workspace structure

2. **Migration Steps**:
   ```bash
   # Export API from source instance
   az apim api export \
     --resource-group rg-source \
     --service-name apim-source \
     --api-id sample-api \
     --export-file /tmp/api-export.json
   
   # Import to target workspace
   az rest \
     --method put \
     --url "https://management.azure.com/.../workspaces/dev/apis/sample-api?..." \
     --body @/tmp/api-export.json
   ```

3. **Validation**:
   - Test all APIs in new workspaces
   - Verify policies and configurations
   - Update client applications

4. **Cutover**:
   - Update DNS/routing
   - Monitor closely
   - Decommission old instances

## Summary

APIM Workspaces provide powerful capabilities for:
- ✅ Multi-environment management within single instance
- ✅ Team-based collaboration and isolation
- ✅ Cost-effective infrastructure sharing
- ✅ Streamlined promotion workflows
- ✅ Flexible organizational patterns

**When to Use Workspaces**:
- Managing multiple environments (dev/test/prod)
- Supporting multiple teams or projects
- Multi-tenant SaaS scenarios
- Cost optimization through shared infrastructure

**When to Use Separate Instances**:
- Regulatory requirements for complete isolation
- Different network configurations per environment
- Independent scaling requirements
- Different geographic regions (though Premium tier supports multi-region)

## Additional Resources

- [Lab 6: APIM Workspaces Hands-On](../labs/lab-06-workspaces/README.md)
- [Azure APIM Workspaces Official Docs](https://learn.microsoft.com/azure/api-management/workspaces-overview)
- [APIM REST API Reference](https://learn.microsoft.com/rest/api/apimanagement/)
- [Terraform APIM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_workspace)

---

**Last Updated**: 2026-02-17  
**API Version**: 2023-09-01-preview
