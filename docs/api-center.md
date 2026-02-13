# Azure API Center Integration

Guide for integrating Azure API Management with Azure API Center for comprehensive API governance and discovery.

## Table of Contents
- [What is Azure API Center?](#what-is-azure-api-center)
- [Integration Benefits](#integration-benefits)
- [Setup and Configuration](#setup-and-configuration)
- [Synchronization Strategies](#synchronization-strategies)
- [Governance and Compliance](#governance-and-compliance)

## What is Azure API Center?

Azure API Center is a centralized service for:
- **API Inventory**: Catalog all APIs across your organization
- **API Discovery**: Enable developers to find and consume APIs
- **API Governance**: Enforce standards and compliance
- **Lifecycle Management**: Track API versions, deprecations, and changes
- **Multi-Source Support**: Include APIs from APIM, API GW, third-party services

### API Center vs. APIM

| Feature | API Center | API Management |
|---------|-----------|----------------|
| **Purpose** | Inventory & Governance | Runtime Gateway & Management |
| **Scope** | Organization-wide catalog | Specific APIM instance |
| **APIs** | Any source (APIM, AWS, Google, on-prem) | APIs managed by APIM |
| **Runtime** | No (metadata only) | Yes (processes requests) |
| **Discovery** | Cross-platform | Within APIM Developer Portal |

**Together**: API Center provides discovery and governance; APIM provides runtime gateway and policies.

## Integration Benefits

### For Organizations
- **Unified Catalog**: Single source of truth for all APIs
- **Governance**: Enforce standards across all API platforms
- **Compliance**: Track API compliance with regulations
- **Cost Management**: Understand API usage across platforms

### For Developers
- **Easy Discovery**: Find APIs without knowing which team owns them
- **Consistent Documentation**: Standardized API specifications
- **Version Tracking**: Understand API lifecycle and deprecations
- **Tooling Integration**: Use VS Code extension for API exploration

### For API Owners
- **Visibility**: Track who's using your APIs
- **Standards Enforcement**: Automated linting and compliance checks
- **Change Management**: Document breaking changes and migrations
- **Analytics**: Understand API adoption

## Setup and Configuration

### Prerequisites

- Azure subscription
- Azure API Management instance
- Contributor access to create API Center

### Create API Center

**Via Azure CLI:**
```bash
# Create API Center instance
az apic create \
  --name apic-contoso \
  --resource-group rg-api-center \
  --location eastus

# Get API Center endpoint
az apic show --name apic-contoso --resource-group rg-api-center --query "apiCenterUri"
```

**Via Bicep:**
```bicep
resource apiCenter 'Microsoft.ApiCenter/services@2024-03-01' = {
  name: 'apic-contoso'
  location: location
  properties: {}
}

output apiCenterEndpoint string = apiCenter.properties.apiCenterUri
```

### Register APIM as Source

**Manually (Portal):**
1. Navigate to API Center
2. Select "APIs" blade
3. Click "Import from API Management"
4. Select APIM instance
5. Choose APIs to import

**Programmatically (REST API):**
```bash
# Get APIM APIs
az apim api list --resource-group rg-apim --service-name apim-instance --output json > apim-apis.json

# Register with API Center (example with REST API)
# See script in scripts/sync-api-center.sh for full implementation
```

### Enable Managed Identity

**For automated sync, enable Managed Identity on both services:**

```bicep
// APIM with Managed Identity
resource apim 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  name: 'apim-instance'
  identity: {
    type: 'SystemAssigned'
  }
  // ... other properties
}

// Grant APIM identity access to API Center
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(apiCenter.id, apim.id, 'contributor')
  scope: apiCenter
  properties: {
    principalId: apim.identity.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor
  }
}
```

## Synchronization Strategies

### 1. Manual Sync (Ad-hoc)

Use when:
- Infrequent API changes
- Small number of APIs
- Testing integration

**Process:**
1. Export API from APIM (OpenAPI spec)
2. Import to API Center via portal or CLI
3. Add metadata (owner, version, lifecycle stage)

### 2. Scheduled Sync (Automated)

Use when:
- Regular API updates
- Multiple APIM instances
- Need consistency

**GitHub Actions Example:**
```yaml
name: Sync APIM to API Center

on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM
  workflow_dispatch:

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Sync APIs
        run: |
          ./scripts/sync-api-center.sh
```

**Script Structure (see `scripts/sync-api-center.sh` for implementation):**
```bash
#!/bin/bash
# 1. Get list of APIs from APIM
# 2. For each API:
#    a. Export OpenAPI spec
#    b. Check if exists in API Center
#    c. Create or update in API Center
#    d. Add metadata (tags, lifecycle, owner)
# 3. Log results
```

### 3. Event-Driven Sync (Advanced)

Use when:
- Real-time sync required
- Large organizations with many APIs
- Complex governance rules

**Architecture:**
```
APIM → Event Grid → Azure Function → API Center
```

**Implementation:**
```bicep
// Event Grid subscription on APIM
resource eventGridSubscription 'Microsoft.EventGrid/eventSubscriptions@2023-12-15-preview' = {
  name: 'apim-to-apicenter'
  scope: apim
  properties: {
    destination: {
      endpointType: 'AzureFunction'
      properties: {
        resourceId: syncFunction.id
      }
    }
    filter: {
      includedEventTypes: [
        'Microsoft.ApiManagement.APICreated'
        'Microsoft.ApiManagement.APIUpdated'
        'Microsoft.ApiManagement.APIDeleted'
      ]
    }
  }
}
```

## Governance and Compliance

### API Metadata Standards

**Required Metadata:**
- **Owner**: Team or individual responsible
- **Lifecycle Stage**: Design, Preview, Active, Deprecated
- **Version**: Semantic version (1.0.0)
- **Tags**: Categories, domains (finance, hr, customer)

**Example Registration:**
```json
{
  "title": "Customer API",
  "kind": "rest",
  "lifecycleStage": "active",
  "version": {
    "name": "v1",
    "lifecycleStage": "active"
  },
  "customProperties": {
    "owner": "customer-team@contoso.com",
    "domain": "customer-management",
    "sla": "99.9%",
    "authentication": "OAuth2"
  }
}
```

### API Standards Enforcement

**Use Spectral or similar tools to enforce:**
- OpenAPI specification compliance
- Naming conventions (kebab-case, camelCase)
- Required headers (correlation-id, api-version)
- Error response formats
- Security requirements (HTTPS, authentication)

**Example Spectral Rule:**
```yaml
# .spectral.yaml
extends: spectral:oas
rules:
  operation-operationId-required:
    severity: error
  
  info-contact-required:
    description: API must have contact information
    given: $.info
    severity: error
    then:
      field: contact
      function: truthy
  
  security-defined:
    description: API must define security schemes
    given: $.securitySchemes
    severity: error
    then:
      function: truthy
```

### Compliance Tracking

**Track Compliance Status:**
- OpenAPI spec quality score
- Security requirements met
- Documentation completeness
- SLA definition
- Deprecation notices

**Example Dashboard Query:**
```kusto
// API Compliance Score (conceptual)
APIMetrics
| extend ComplianceScore = (
    iff(HasOpenAPISpec, 25, 0) +
    iff(HasAuthentication, 25, 0) +
    iff(HasDocumentation, 25, 0) +
    iff(HasSLA, 25, 0)
)
| where ComplianceScore < 100
| project APIName, Owner, ComplianceScore, MissingRequirements
```

### Deprecation Management

**Process:**
1. Mark API as "Deprecated" in API Center
2. Set sunset date
3. Notify consumers
4. Monitor usage (should decline)
5. Remove after sunset date + grace period

**Example Policy to Warn Consumers:**
```xml
<policies>
  <inbound>
    <choose>
      <when condition="@(context.Api.Name == "legacy-api-v1")">
        <set-header name="X-API-Deprecated" exists-action="override">
          <value>true</value>
        </set-header>
        <set-header name="X-API-Sunset-Date" exists-action="override">
          <value>2025-06-30</value>
        </set-header>
        <set-header name="X-API-Migration-Info" exists-action="override">
          <value>https://docs.contoso.com/api/v2-migration</value>
        </set-header>
      </when>
    </choose>
  </inbound>
</policies>
```

## VS Code Integration

**Use Azure API Center VS Code extension:**

1. Install extension: `ms-azuretools.vscode-azureapicenter`
2. Sign in to Azure
3. Select API Center instance
4. Browse APIs
5. Generate client code
6. Test APIs directly from VS Code

**Benefits:**
- Discover APIs without leaving IDE
- Generate SDKs in multiple languages
- Test APIs with built-in HTTP client
- Stay updated on API changes

## Best Practices

1. **Single Source of Truth**: Make API Center the authoritative catalog
2. **Automate Sync**: Don't rely on manual processes
3. **Enforce Standards**: Use linting and validation
4. **Document Everything**: OpenAPI specs, examples, guides
5. **Track Ownership**: Every API must have an owner
6. **Monitor Compliance**: Regular audits and dashboards
7. **Communicate Changes**: Notify consumers of deprecations
8. **Version Thoughtfully**: Use semantic versioning
9. **Tag Consistently**: Use standard taxonomy (domain, team, type)
10. **Integrate with SDLC**: API registration as part of CI/CD

## Example Workflow

### New API Lifecycle

1. **Design**: Create OpenAPI spec, register in API Center (Design stage)
2. **Review**: Architecture review, security review
3. **Implement**: Build API in APIM or backend
4. **Test**: Deploy to dev APIM, update API Center (Preview stage)
5. **Approve**: Stakeholder approval, update API Center
6. **Deploy**: Production deployment, sync to API Center (Active stage)
7. **Monitor**: Track usage, compliance, performance
8. **Deprecate**: When needed, mark as Deprecated, set sunset date
9. **Retire**: Remove from APIM, archive in API Center

## Future Capabilities (Roadmap)

Azure API Center is evolving. Expected features:
- Enhanced governance policies
- Built-in API analytics
- Automated compliance scoring
- Integration with Azure DevOps
- API marketplace capabilities
- Consumer feedback and ratings

## Additional Resources

- [Azure API Center Documentation](https://learn.microsoft.com/azure/api-center/)
- [VS Code Extension](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azureapicenter)
- [API Governance Best Practices](https://learn.microsoft.com/azure/architecture/best-practices/api-design)

## Next Steps

- [Troubleshooting](troubleshooting.md) - Debug sync issues
- [Concepts](concepts.md) - Understand API governance fundamentals
- Use `scripts/sync-api-center.sh` for automated synchronization

---

**API Governance** is not optional. API Center makes it manageable at scale.
