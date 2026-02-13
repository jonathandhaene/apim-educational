# Lab 5: Operations & Architecture - API Center, AI Gateway, and Best Practices

**Level**: Operations & Architecture  
**Duration**: 90-120 minutes  
**Prerequisites**: Completed Labs 1-4 or have comprehensive APIM deployment

## Learning Objectives

By the end of this lab, you will:
- Synchronize APIs with Azure API Center for governance
- Implement AI Gateway policies for Azure OpenAI and LLM APIs
- Create advanced observability dashboards with KQL queries
- Understand disaster recovery and business continuity strategies
- Apply cost optimization techniques
- Review production readiness checklist and best practices

## Architecture

```
API Governance Layer
    ├── Azure API Center (Inventory & Catalog)
    │   └── APIM Sync
    │
API Gateway Layer
    ├── APIM (Multi-region)
    │   ├── AI Gateway Policies
    │   └── Advanced Policies
    │
Observability Layer
    ├── Application Insights
    ├── Log Analytics (KQL)
    └── Azure Monitor Dashboards
    │
Backend Layer
    ├── Azure OpenAI
    ├── APIs
    └── Microservices
```

## Prerequisites

- Completed previous labs or have APIM with APIs deployed
- Azure CLI and PowerShell/Bash
- Access to create Azure API Center resource
- Optional: Azure OpenAI resource for AI Gateway testing

## Step 1: Azure API Center Integration

### Create API Center

```bash
# Set variables
RESOURCE_GROUP="rg-apim-lab"
LOCATION="eastus"
API_CENTER_NAME="apicenter-${RANDOM}"
APIM_NAME="apim-lab-yourname"

# Create API Center (if not exists)
az apic create \
  --resource-group ${RESOURCE_GROUP} \
  --name ${API_CENTER_NAME} \
  --location ${LOCATION}

echo "API Center created: ${API_CENTER_NAME}"
```

### Register APIs in API Center

```bash
# Register an API in API Center
az apic api register \
  --resource-group ${RESOURCE_GROUP} \
  --service-name ${API_CENTER_NAME} \
  --api-id sample-api \
  --title "Sample API" \
  --description "Sample backend API for APIM labs" \
  --type REST

# Register API version
az apic api version create \
  --resource-group ${RESOURCE_GROUP} \
  --service-name ${API_CENTER_NAME} \
  --api-id sample-api \
  --version-id v1 \
  --title "Version 1.0" \
  --lifecycle-stage "production"

# Add API definition (OpenAPI spec)
az apic api definition create \
  --resource-group ${RESOURCE_GROUP} \
  --service-name ${API_CENTER_NAME} \
  --api-id sample-api \
  --version-id v1 \
  --definition-id openapi \
  --title "OpenAPI Definition" \
  --description "OpenAPI 3.0 specification"

# Import OpenAPI spec
az apic api definition import-specification \
  --resource-group ${RESOURCE_GROUP} \
  --service-name ${API_CENTER_NAME} \
  --api-id sample-api \
  --version-id v1 \
  --definition-id openapi \
  --format OpenAPI \
  --specification-file ../../src/functions-sample/openapi.json
```

### Sync APIM with API Center

Use the sync script from [../../scripts/sync-api-center.sh](../../scripts/sync-api-center.sh):

```bash
cd ../../scripts

# Set environment variables
export RESOURCE_GROUP="${RESOURCE_GROUP}"
export APIM_NAME="${APIM_NAME}"
export API_CENTER_NAME="${API_CENTER_NAME}"

# Run sync script
./sync-api-center.sh

# Expected output: APIs from APIM registered in API Center
```

### Add Metadata and Tags

```bash
# Add environment metadata
az apic api deployment create \
  --resource-group ${RESOURCE_GROUP} \
  --service-name ${API_CENTER_NAME} \
  --api-id sample-api \
  --deployment-id prod-deployment \
  --title "Production Deployment" \
  --description "APIM production gateway" \
  --server '{"runtimeUri": ["https://'${APIM_NAME}'.azure-api.net/sample"]}'

# Add metadata properties (custom fields)
# This helps with governance, discovery, and compliance tracking
```

### Validation

```bash
# List all APIs in API Center
az apic api list \
  --resource-group ${RESOURCE_GROUP} \
  --service-name ${API_CENTER_NAME} \
  --output table

# Get API details
az apic api show \
  --resource-group ${RESOURCE_GROUP} \
  --service-name ${API_CENTER_NAME} \
  --api-id sample-api \
  --output json
```

**Expected Output**: APIs from APIM are registered in API Center with versions, definitions, and metadata.

See [API Center documentation](../../docs/api-center.md) for more details.

## Step 2: AI Gateway for Azure OpenAI

### Prerequisites

```bash
# Create Azure OpenAI resource (if not exists)
OPENAI_NAME="openai-${RANDOM}"
az cognitiveservices account create \
  --name ${OPENAI_NAME} \
  --resource-group ${RESOURCE_GROUP} \
  --location ${LOCATION} \
  --kind OpenAI \
  --sku S0 \
  --custom-domain ${OPENAI_NAME}

# Deploy a model (e.g., GPT-4)
az cognitiveservices account deployment create \
  --name ${OPENAI_NAME} \
  --resource-group ${RESOURCE_GROUP} \
  --deployment-name gpt4 \
  --model-name gpt-4 \
  --model-version "0613" \
  --model-format OpenAI \
  --sku-capacity 10 \
  --sku-name "Standard"

# Get OpenAI endpoint and key
OPENAI_ENDPOINT=$(az cognitiveservices account show \
  --name ${OPENAI_NAME} \
  --resource-group ${RESOURCE_GROUP} \
  --query properties.endpoint -o tsv)

OPENAI_KEY=$(az cognitiveservices account keys list \
  --name ${OPENAI_NAME} \
  --resource-group ${RESOURCE_GROUP} \
  --query key1 -o tsv)

echo "OpenAI Endpoint: ${OPENAI_ENDPOINT}"
```

### Import Azure OpenAI API to APIM

```bash
# Import Azure OpenAI as backend
az apim api create \
  --resource-group ${RESOURCE_GROUP} \
  --service-name ${APIM_NAME} \
  --api-id azure-openai \
  --path openai \
  --display-name "Azure OpenAI API" \
  --service-url "${OPENAI_ENDPOINT}/openai" \
  --protocols https

# Add operations (POST /deployments/{deployment-id}/chat/completions)
az apim api operation create \
  --resource-group ${RESOURCE_GROUP} \
  --service-name ${APIM_NAME} \
  --api-id azure-openai \
  --url-template "/deployments/{deployment-id}/chat/completions" \
  --method POST \
  --display-name "Chat Completions" \
  --description "Create chat completions"
```

### Apply AI Gateway Policy

See the complete AI Gateway policy in [../../policies/ai-gateway.xml](../../policies/ai-gateway.xml).

Key features of AI Gateway policy:
- **Token limiting**: Enforce token limits per subscription
- **Prompt sanitization**: Filter sensitive content
- **Response transformation**: Standardize response format
- **Cost tracking**: Log token usage for billing
- **Load balancing**: Distribute across multiple OpenAI instances
- **Retry with backoff**: Handle rate limits gracefully

```xml
<policies>
    <inbound>
        <base />
        <!-- Set backend -->
        <set-backend-service base-url="${OPENAI_ENDPOINT}/openai" />
        
        <!-- Add API key -->
        <set-header name="api-key" exists-action="override">
            <value>{{azure-openai-key}}</value>
        </set-header>
        
        <!-- Token limiting -->
        <rate-limit-by-key calls="100" 
                           renewal-period="3600" 
                           counter-key="@(context.Subscription.Id + "-tokens")" />
        
        <!-- Log request tokens -->
        <set-variable name="requestTokens" 
                      value="@(context.Request.Body.As<JObject>(preserveContent: true)["max_tokens"])" />
        
        <!-- Sanitize prompt (remove sensitive patterns) -->
        <choose>
            <when condition="@(context.Request.Body.As<string>(preserveContent: true).Contains("password"))">
                <return-response>
                    <set-status code="400" reason="Bad Request" />
                    <set-body>{"error": "Sensitive content detected in prompt"}</set-body>
                </return-response>
            </when>
        </choose>
    </inbound>
    <backend>
        <retry condition="@(context.Response.StatusCode == 429)" 
               count="3" 
               interval="2" 
               first-fast-retry="true" />
        <base />
    </backend>
    <outbound>
        <base />
        <!-- Log token usage -->
        <log-to-eventhub logger-id="token-logger">
            @{
                var response = context.Response.Body.As<JObject>(preserveContent: true);
                return new JObject(
                    new JProperty("subscriptionId", context.Subscription.Id),
                    new JProperty("requestTokens", context.Variables["requestTokens"]),
                    new JProperty("responseTokens", response["usage"]["total_tokens"]),
                    new JProperty("timestamp", DateTime.UtcNow)
                ).ToString();
            }
        </log-to-eventhub>
    </outbound>
</policies>
```

### Test AI Gateway

```bash
# Test chat completion through APIM
curl -X POST "https://${APIM_NAME}.azure-api.net/openai/deployments/gpt4/chat/completions?api-version=2024-02-15-preview" \
  -H "Content-Type: application/json" \
  -H "Ocp-Apim-Subscription-Key: ${SUBSCRIPTION_KEY}" \
  -d '{
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "What is Azure API Management?"}
    ],
    "max_tokens": 100
  }'
```

**Expected Output**: Chat completion response with token usage logged.

See [AI Gateway documentation](../../docs/ai-gateway.md) for advanced patterns.

## Step 3: Advanced Observability with KQL

### Performance Analysis Queries

Create a workbook in Azure Monitor with these KQL queries:

**1. Request Performance by Operation**
```kusto
ApiManagementGatewayLogs
| where TimeGenerated > ago(24h)
| summarize 
    Count = count(),
    P50 = percentile(TotalTime, 50),
    P95 = percentile(TotalTime, 95),
    P99 = percentile(TotalTime, 99),
    MaxTime = max(TotalTime)
    by ApiId, OperationId
| order by P95 desc
```

**2. Error Rate Trending**
```kusto
ApiManagementGatewayLogs
| where TimeGenerated > ago(7d)
| summarize 
    TotalRequests = count(),
    Errors = countif(ResponseCode >= 400),
    ErrorRate = round(100.0 * countif(ResponseCode >= 400) / count(), 2)
    by bin(TimeGenerated, 1h)
| render timechart 
```

**3. Top Consumers by Token Usage** (for AI Gateway)
```kusto
ApiManagementGatewayLogs
| where TimeGenerated > ago(24h)
| where ApiId == "azure-openai"
| extend TokenCount = toint(parse_json(ResponseBody).usage.total_tokens)
| summarize TotalTokens = sum(TokenCount) by SubscriptionId
| order by TotalTokens desc
| take 10
```

**4. Backend Health Check**
```kusto
ApiManagementGatewayLogs
| where TimeGenerated > ago(1h)
| where ResponseCode == 503 or ResponseCode == 504
| summarize FailureCount = count() by BackendId, bin(TimeGenerated, 5m)
| render timechart
```

**5. Cache Hit Rate**
```kusto
ApiManagementGatewayLogs
| where TimeGenerated > ago(24h)
| extend CacheHit = iff(Cache == "hit", 1, 0)
| summarize 
    TotalRequests = count(),
    CacheHits = sum(CacheHit),
    HitRate = round(100.0 * sum(CacheHit) / count(), 2)
    by ApiId
| order by HitRate desc
```

**6. Geographic Distribution**
```kusto
ApiManagementGatewayLogs
| where TimeGenerated > ago(24h)
| extend Country = geo_info_from_ip_address(ClientIp).country
| summarize RequestCount = count() by Country
| order by RequestCount desc
| take 20
| render piechart
```

### Create Azure Monitor Dashboard

```bash
# Export queries to dashboard template
# Navigate to: Azure Portal → Dashboards → New dashboard
# Add tiles with KQL queries above
# Share with team

# Or use Azure CLI to create dashboard programmatically
az portal dashboard create \
  --resource-group ${RESOURCE_GROUP} \
  --name apim-ops-dashboard \
  --input-path dashboard-template.json \
  --location ${LOCATION}
```

See [Observability documentation](../../docs/observability.md) for complete query library.

## Step 4: Disaster Recovery & Business Continuity

### Multi-Region Deployment Strategy

**Active-Passive Setup**:
```bash
# Primary region: eastus (active)
# Secondary region: westus (passive)

# Deploy APIM to secondary region
az apim create \
  --resource-group ${RESOURCE_GROUP} \
  --name apim-lab-dr \
  --location westus \
  --publisher-email admin@contoso.com \
  --publisher-name "Contoso DR" \
  --sku-name Premium

# Configure Traffic Manager for failover
az network traffic-manager profile create \
  --resource-group ${RESOURCE_GROUP} \
  --name tm-apim \
  --routing-method Priority \
  --unique-dns-name apim-lab-tm
```

**Active-Active Setup** (Premium tier only):
```bash
# Add secondary region to existing APIM
az apim update \
  --resource-group ${RESOURCE_GROUP} \
  --name ${APIM_NAME} \
  --add additionalLocations location=westus skuType=Premium capacity=1

# Traffic automatically distributed across regions
```

### Backup and Restore

```bash
# Backup APIM configuration
STORAGE_ACCOUNT="stbackup${RANDOM}"
az storage account create \
  --name ${STORAGE_ACCOUNT} \
  --resource-group ${RESOURCE_GROUP} \
  --location ${LOCATION} \
  --sku Standard_LRS

# Get storage key
STORAGE_KEY=$(az storage account keys list \
  --account-name ${STORAGE_ACCOUNT} \
  --resource-group ${RESOURCE_GROUP} \
  --query "[0].value" -o tsv)

# Create backup container
az storage container create \
  --name apim-backups \
  --account-name ${STORAGE_ACCOUNT} \
  --account-key ${STORAGE_KEY}

# Backup APIM (via REST API or Portal)
az apim backup \
  --resource-group ${RESOURCE_GROUP} \
  --name ${APIM_NAME} \
  --storage-account-name ${STORAGE_ACCOUNT} \
  --storage-account-key ${STORAGE_KEY} \
  --storage-account-container apim-backups \
  --backup-name "apim-backup-$(date +%Y%m%d)"

# Restore from backup (if needed)
# az apim restore \
#   --resource-group ${RESOURCE_GROUP} \
#   --name ${APIM_NAME} \
#   --storage-account-name ${STORAGE_ACCOUNT} \
#   --storage-account-key ${STORAGE_KEY} \
#   --storage-account-container apim-backups \
#   --backup-name "apim-backup-20240101"
```

### DR Checklist

- [ ] Multi-region deployment configured
- [ ] Traffic Manager or Front Door for global routing
- [ ] Regular backups scheduled (weekly minimum)
- [ ] Backup restoration tested (quarterly)
- [ ] Runbook documented for DR procedures
- [ ] RTO and RPO targets defined and validated
- [ ] DNS TTL reduced for faster failover (< 5 minutes)
- [ ] Health probes configured on all endpoints
- [ ] Monitoring alerts for regional outages
- [ ] Team trained on failover procedures

## Step 5: Cost Optimization

### Cost Analysis

```bash
# Get APIM cost estimate
az consumption usage list \
  --start-date $(date -d "30 days ago" +%Y-%m-%d) \
  --end-date $(date +%Y-%m-%d) \
  --query "[?contains(instanceName, 'apim')]" \
  --output table

# Analyze consumption tier usage
# Navigate to: APIM → Metrics → Requests (count)
# Compare with pricing tiers for optimal cost
```

### Cost Optimization Strategies

**1. Right-Size Your Tier**
- **Consumption**: Best for variable/low traffic (<1M requests/month)
- **Developer**: Learning and non-production (~$50/month)
- **Basic**: Small production workloads (~$150/month)
- **Standard**: Medium production (~$750/month)
- **Premium**: Enterprise/multi-region (~$3000+/month)

**2. Use Caching Aggressively**
```bash
# Calculate cache savings
# Cached requests don't hit backend = cost reduction
# Example: 70% cache hit rate = 70% backend cost savings
```

**3. Enable Autoscaling** (Premium tier)
```bash
az monitor autoscale create \
  --resource-group ${RESOURCE_GROUP} \
  --resource ${APIM_NAME} \
  --resource-type Microsoft.ApiManagement/service \
  --name autoscale-apim \
  --min-count 1 \
  --max-count 3 \
  --count 1
```

**4. Monitor and Optimize**
- Delete unused APIs and products
- Remove expensive policies (transformation overhead)
- Optimize backend response times
- Use lightweight self-hosted gateways for edge scenarios

### Cost Optimization Checklist

- [ ] Tier matches actual usage pattern
- [ ] Autoscaling enabled for variable workloads
- [ ] Caching configured with high hit rate (>50%)
- [ ] Unused APIs and subscriptions removed
- [ ] Self-hosted gateway for edge/on-prem scenarios
- [ ] Backend services optimized for performance
- [ ] Budget alerts configured in Azure Cost Management
- [ ] Regular cost reviews scheduled (monthly)

## Step 6: Production Readiness Checklist

### Security
- [ ] Managed Identity enabled for Azure service connections
- [ ] All secrets stored in Key Vault
- [ ] JWT validation configured for APIs
- [ ] Subscription keys rotated regularly
- [ ] IP filtering applied where needed
- [ ] Private endpoints for internal APIs
- [ ] WAF configured (Front Door or App Gateway)
- [ ] TLS 1.2+ enforced

### Networking
- [ ] VNet integration configured (if internal)
- [ ] Private DNS zones set up
- [ ] NSG rules documented and applied
- [ ] Custom domains configured with valid certificates
- [ ] CDN/Front Door for global distribution

### Observability
- [ ] Application Insights integrated
- [ ] Log Analytics workspace configured
- [ ] Diagnostic settings enabled for all categories
- [ ] Azure Monitor dashboards created
- [ ] Alerts configured for critical metrics
- [ ] Log retention policy defined

### Operations
- [ ] CI/CD pipelines for API deployment
- [ ] Infrastructure as Code (Bicep/Terraform)
- [ ] API versioning strategy implemented
- [ ] Revision workflow for safe deployments
- [ ] Backup and restore procedures tested
- [ ] DR plan documented and validated
- [ ] Runbooks for common scenarios
- [ ] On-call rotation and escalation policy

### Governance
- [ ] APIs registered in API Center
- [ ] API documentation published
- [ ] Developer portal configured
- [ ] Subscription approval workflow
- [ ] Rate limits and quotas per tier
- [ ] Product structure defined
- [ ] API lifecycle management process

## Step 7: Cleanup

```bash
# Delete API Center
az apic delete \
  --resource-group ${RESOURCE_GROUP} \
  --name ${API_CENTER_NAME}

# Delete Azure OpenAI
az cognitiveservices account delete \
  --name ${OPENAI_NAME} \
  --resource-group ${RESOURCE_GROUP}

# Delete entire resource group (all labs)
az group delete --name ${RESOURCE_GROUP} --yes --no-wait
```

## 🎓 What You Learned

- ✅ Registered and synced APIs with Azure API Center
- ✅ Implemented AI Gateway policies for Azure OpenAI
- ✅ Created advanced KQL queries for observability
- ✅ Understood disaster recovery strategies
- ✅ Applied cost optimization techniques
- ✅ Reviewed production readiness checklist

## 🎉 Congratulations!

You've completed all five APIM labs! You now have comprehensive knowledge of:
- API gateway deployment and management
- Security and authentication patterns
- Advanced networking and private connectivity
- Self-hosted gateway and hybrid scenarios
- Performance optimization and caching
- Enterprise operations and governance
- AI Gateway for modern LLM APIs

## 📚 Additional Resources

- [API Center Documentation](../../docs/api-center.md)
- [AI Gateway Patterns](../../docs/ai-gateway.md)
- [Observability Guide](../../docs/observability.md)
- [Production Best Practices](../../docs/concepts.md)
- [Cost Optimization](../../docs/tiers-and-skus.md)

## 🚀 Next Steps

- Deploy APIM to your production environment
- Migrate existing APIs to APIM
- Implement advanced patterns from [docs/](../../docs/)
- Contribute to this repository
- Share your experience with the community

## ❓ Troubleshooting

**Issue**: API Center sync fails  
**Solution**: Verify APIM and API Center are in same subscription, check script permissions

**Issue**: AI Gateway token logging not working  
**Solution**: Ensure Event Hub logger is configured, verify policy syntax

**Issue**: KQL queries returning no data  
**Solution**: Check diagnostic settings enabled, wait 5-10 minutes for data flow

**Issue**: Backup fails  
**Solution**: Verify storage account permissions, ensure Premium tier for backup feature

---

**Thank you for completing the Azure API Management labs!** 🎓🚀

For questions, issues, or contributions, visit the [GitHub repository](https://github.com/jonathandhaene/apim-educational).
