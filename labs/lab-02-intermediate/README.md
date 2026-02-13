# Lab 2: Intermediate API Management with Diagnostics and Security

**Level**: Intermediate  
**Duration**: 60-90 minutes  
**Prerequisites**: Completed Lab 1 or have an existing APIM instance

## Learning Objectives

By the end of this lab, you will:
- Configure comprehensive diagnostics with Application Insights and Log Analytics
- Implement JWT validation for OAuth/OIDC authentication
- Apply advanced rate limiting and quota policies
- Run k6 load tests to validate performance and limits
- Monitor API health and troubleshoot issues using logs

## Architecture

```
Client → APIM Gateway → Backend API
         ↓         ↓
    App Insights  Log Analytics
         ↓
    KQL Queries & Dashboards
```

## Prerequisites

- Completed [Lab 1: Beginner](../lab-01-beginner/README.md) or existing APIM instance
- Azure CLI installed and logged in
- [k6 load testing tool](https://k6.io/docs/getting-started/installation/) installed
- Postman or VS Code with REST Client extension

## Step 1: Configure Diagnostics

### Enable Application Insights

If not already configured from Lab 1:

```bash
# Set variables
RESOURCE_GROUP="rg-apim-lab"
APIM_NAME="apim-lab-yourname"
LOCATION="eastus"

# Create Application Insights
az monitor app-insights component create \
  --app apim-insights-${APIM_NAME} \
  --location ${LOCATION} \
  --resource-group ${RESOURCE_GROUP} \
  --application-type web

# Get instrumentation key
INSTRUMENTATION_KEY=$(az monitor app-insights component show \
  --app apim-insights-${APIM_NAME} \
  --resource-group ${RESOURCE_GROUP} \
  --query instrumentationKey -o tsv)

# Link to APIM (via portal or ARM template)
# Navigate to APIM → Application Insights → Enable → Select resource
```

### Enable Log Analytics

```bash
# Create Log Analytics workspace
az monitor log-analytics workspace create \
  --workspace-name la-apim-${APIM_NAME} \
  --resource-group ${RESOURCE_GROUP} \
  --location ${LOCATION}

# Get workspace ID
WORKSPACE_ID=$(az monitor log-analytics workspace show \
  --workspace-name la-apim-${APIM_NAME} \
  --resource-group ${RESOURCE_GROUP} \
  --query customerId -o tsv)

# Enable diagnostic settings for APIM
az monitor diagnostic-settings create \
  --name apim-diagnostics \
  --resource $(az apim show --name ${APIM_NAME} --resource-group ${RESOURCE_GROUP} --query id -o tsv) \
  --workspace $(az monitor log-analytics workspace show --workspace-name la-apim-${APIM_NAME} --resource-group ${RESOURCE_GROUP} --query id -o tsv) \
  --logs '[{"category": "GatewayLogs", "enabled": true}]' \
  --metrics '[{"category": "AllMetrics", "enabled": true}]'
```

### Validation

After a few minutes, verify logs are flowing:

```bash
# Query Log Analytics
az monitor log-analytics query \
  --workspace ${WORKSPACE_ID} \
  --analytics-query "ApiManagementGatewayLogs | take 10" \
  --out table
```

**Expected Output**: Recent gateway log entries with timestamps, API IDs, and response codes.

## Step 2: Implement JWT Validation

### Register Azure AD Application

```bash
# Create Azure AD app registration
APP_NAME="apim-api-${APIM_NAME}"
APP_ID=$(az ad app create \
  --display-name ${APP_NAME} \
  --sign-in-audience AzureADMyOrg \
  --query appId -o tsv)

# Create service principal
az ad sp create --id ${APP_ID}

# Get tenant ID
TENANT_ID=$(az account show --query tenantId -o tsv)

echo "App ID: ${APP_ID}"
echo "Tenant ID: ${TENANT_ID}"
```

### Apply JWT Validation Policy

See the complete JWT validation policy in [../../policies/jwt-validate.xml](../../policies/jwt-validate.xml).

1. Navigate to APIM → APIs → Your API → All operations
2. In Inbound processing, click `</>` (code editor)
3. Add this policy (update with your tenant ID and app ID):

```xml
<inbound>
    <base />
    <validate-jwt header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Unauthorized. Access token is missing or invalid.">
        <openid-config url="https://login.microsoftonline.com/{your-tenant-id}/v2.0/.well-known/openid-configuration" />
        <audiences>
            <audience>api://{your-app-id}</audience>
        </audiences>
        <issuers>
            <issuer>https://sts.windows.net/{your-tenant-id}/</issuer>
        </issuers>
        <required-claims>
            <claim name="aud" match="any">
                <value>api://{your-app-id}</value>
            </claim>
        </required-claims>
    </validate-jwt>
</inbound>
```

### Test JWT Validation

```bash
# Get a token (requires Azure CLI with user context)
TOKEN=$(az account get-access-token --resource api://${APP_ID} --query accessToken -o tsv)

# Test with valid token
curl -X GET "${APIM_URL}/sample/httpTrigger?name=JWT" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Ocp-Apim-Subscription-Key: ${SUBSCRIPTION_KEY}"

# Test without token (should fail with 401)
curl -X GET "${APIM_URL}/sample/httpTrigger?name=NoAuth" \
  -H "Ocp-Apim-Subscription-Key: ${SUBSCRIPTION_KEY}"
```

**Expected Output**:
- With token: `200 OK` with API response
- Without token: `401 Unauthorized` with error message

## Step 3: Advanced Rate Limiting Policies

### Apply Quota and Rate Limit

Replace the simple rate limit from Lab 1 with a more sophisticated policy:

```xml
<inbound>
    <base />
    <!-- Rate limit: 100 calls per hour -->
    <rate-limit-by-key calls="100" 
                       renewal-period="3600" 
                       counter-key="@(context.Subscription.Id)" />
    
    <!-- Quota: 10,000 calls per day -->
    <quota-by-key calls="10000" 
                  renewal-period="86400" 
                  counter-key="@(context.Subscription.Id)" />
    
    <!-- Different limits for premium tier -->
    <choose>
        <when condition="@(context.Subscription.Name.Contains("premium"))">
            <rate-limit-by-key calls="500" 
                             renewal-period="3600" 
                             counter-key="@(context.Subscription.Id)" />
        </when>
    </choose>
</inbound>
```

See complete examples in [../../policies/rate-limit.xml](../../policies/rate-limit.xml).

### Validation

Test the rate limit:

```bash
# Run 110 requests quickly to hit the hourly limit
for i in {1..110}; do
  curl -s "${APIM_URL}/sample/httpTrigger?name=RateTest${i}" \
    -H "Ocp-Apim-Subscription-Key: ${SUBSCRIPTION_KEY}" \
    -w "\nStatus: %{http_code}\n" >> /tmp/rate-test.log
done

# Check for 429 responses
grep "429" /tmp/rate-test.log | wc -l
```

**Expected Output**: At least 10 requests should return `429 Too Many Requests`.

## Step 4: Load Testing with k6

### Install k6

```bash
# macOS
brew install k6

# Ubuntu/Debian
sudo gpg -k
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6

# Windows (via Chocolatey)
choco install k6
```

### Run Load Test

Use the provided k6 script from [../../tests/k6/smoke-test.js](../../tests/k6/smoke-test.js):

```bash
cd ../../tests/k6

# Set environment variables
export APIM_URL="https://apim-lab-yourname.azure-api.net"
export SUBSCRIPTION_KEY="your-subscription-key"

# Run smoke test (10 VUs for 30 seconds)
k6 run --vus 10 --duration 30s smoke-test.js

# Run load test (50 VUs ramping up)
k6 run load-test.js
```

### Analyze Results

k6 will output metrics including:

```
✓ status is 200
✓ response time < 500ms

checks.........................: 100.00% ✓ 450 ✗ 0
http_req_duration..............: avg=120ms min=45ms med=110ms max=450ms p(90)=180ms p(95)=220ms
http_reqs......................: 450     15/s
```

**Expected Metrics**:
- `http_req_duration`: Average response time should be < 500ms
- `http_req_failed`: Should be 0% or near 0%
- `checks`: Should be 100% passing

## Step 5: Query Logs for Insights

### Application Insights Queries

Navigate to Application Insights → Logs and run:

**Request Performance**:
```kusto
requests
| where timestamp > ago(1h)
| where cloud_RoleName contains "apim"
| summarize 
    RequestCount = count(),
    AvgDuration = avg(duration),
    P95Duration = percentile(duration, 95),
    P99Duration = percentile(duration, 99)
    by operation_Name
| order by RequestCount desc
```

**Error Rate**:
```kusto
requests
| where timestamp > ago(1h)
| where cloud_RoleName contains "apim"
| summarize 
    Total = count(),
    Failed = countif(success == false),
    FailureRate = 100.0 * countif(success == false) / count()
    by bin(timestamp, 5m)
| render timechart
```

### Log Analytics Queries

Navigate to Log Analytics workspace → Logs:

**API Gateway Logs**:
```kusto
ApiManagementGatewayLogs
| where TimeGenerated > ago(1h)
| project 
    TimeGenerated,
    ApiId,
    Method,
    Url,
    ResponseCode,
    ResponseSize,
    TotalTime,
    ClientIp
| order by TimeGenerated desc
| take 100
```

**Rate Limit Violations**:
```kusto
ApiManagementGatewayLogs
| where TimeGenerated > ago(1h)
| where ResponseCode == 429
| summarize ViolationCount = count() by bin(TimeGenerated, 5m), ApiId
| render timechart
```

**Top APIs by Request Count**:
```kusto
ApiManagementGatewayLogs
| where TimeGenerated > ago(24h)
| summarize RequestCount = count() by ApiId
| order by RequestCount desc
| take 10
```

## Step 6: Cleanup

Keep your APIM instance for Lab 3, but optionally remove diagnostic resources:

```bash
# Keep APIM but clean up test resources if needed
# Note: Diagnostic data is useful for next labs

# To remove everything:
# az group delete --name ${RESOURCE_GROUP} --yes --no-wait
```

## 🎓 What You Learned

- ✅ Configured Application Insights for real-time monitoring
- ✅ Set up Log Analytics for query-based diagnostics
- ✅ Implemented JWT validation for OAuth/OIDC flows
- ✅ Applied advanced rate limiting and quota policies
- ✅ Performed load testing with k6
- ✅ Analyzed logs with KQL queries

## 📚 Next Steps

Continue to [Lab 3: Advanced](../lab-03-advanced/README.md) to learn about:
- VNet integration for private/internal mode
- Private endpoints configuration
- Azure Key Vault integration for secrets
- API versioning and revision strategies

## 📖 Additional Resources

- [Application Insights for APIM](https://learn.microsoft.com/azure/api-management/api-management-howto-app-insights)
- [JWT Validation Policy](https://learn.microsoft.com/azure/api-management/api-management-access-restriction-policies#ValidateJWT)
- [Rate Limiting Policies](https://learn.microsoft.com/azure/api-management/api-management-access-restriction-policies)
- [k6 Documentation](https://k6.io/docs/)
- [KQL Query Reference](https://learn.microsoft.com/azure/data-explorer/kusto/query/)

## ❓ Troubleshooting

**Issue**: App Insights not showing data  
**Solution**: Wait 5-10 minutes for initial data flow, ensure logger is enabled

**Issue**: JWT validation always fails  
**Solution**: Verify tenant ID and audience are correct, check token expiration

**Issue**: Rate limit not triggering  
**Solution**: Ensure counter-key is unique per test, check renewal period

**Issue**: k6 installation fails  
**Solution**: Use alternative methods from [k6 installation docs](https://k6.io/docs/getting-started/installation/)

---

**Congratulations!** You've mastered intermediate APIM concepts. Ready for Lab 3? 🚀
