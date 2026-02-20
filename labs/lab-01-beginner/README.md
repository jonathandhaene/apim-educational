# Lab 1: Getting Started with Azure API Management

**Level**: Beginner  
**Duration**: 45-60 minutes  
**Prerequisites**: Azure subscription, Azure CLI

> **⚠️ Educational Disclaimer**: This repository is provided for educational and learning purposes only. All content, including pricing estimates, tier recommendations, and infrastructure templates, should be validated and adapted for your specific production requirements. Azure API Management features, pricing, and best practices evolve frequently—always consult the <a href="https://learn.microsoft.com/azure/api-management/">official Azure documentation</a> and <a href="https://azure.microsoft.com/pricing/calculator/">Azure Pricing Calculator</a> for the most current information before making production decisions.

## Learning Objectives

By the end of this lab, you will:
- Deploy an Azure API Management instance
- Import a sample API using OpenAPI
- Apply basic policies (rate limiting, caching)
- Test the API using Postman or REST Client
- View logs and metrics in Application Insights

## Architecture

```
Client → APIM Gateway → Azure Function (Sample API)
         ↓
    Application Insights (Logging)
```

## Step 1: Deploy API Management

### Option A: Using Azure Portal

1. Navigate to Azure Portal
2. Create a resource → Integration → API Management
3. Fill in details:
   - Name: `apim-lab-{yourname}`
   - Pricing tier: **Developer** (lowest cost for learning)
   - Organization name: Your name
   - Admin email: Your email
4. Click "Review + create" → "Create"
5. **Wait 30-45 minutes** for provisioning

### Option B: Using Bicep (Faster for repeated deployments)

```bash
# Clone this repository
git clone https://github.com/jonathandhaene/apim-educational.git
cd apim-educational

# Login to Azure
az login
az account set --subscription "<your-subscription-id>"

# Deploy
./scripts/deploy-apim.sh -g rg-apim-lab -l eastus

# Wait for deployment to complete (~30-45 minutes)
```

## Step 2: Deploy Sample Backend API

Deploy the sample Azure Function:

```bash
# Navigate to function directory
cd src/functions-sample

# Install dependencies
npm install

# Deploy to Azure (create Function App first)
az functionapp create \
  --resource-group rg-apim-lab \
  --name func-apim-lab-{yourname} \
  --storage-account stlabstorage \
  --consumption-plan-location eastus \
  --runtime node \
  --functions-version 4

# Deploy function code
func azure functionapp publish func-apim-lab-{yourname}
```

## Step 3: Import API into APIM

### Via Azure Portal

1. Navigate to your APIM instance
2. APIs → Add API → OpenAPI
3. Select "Full"
4. OpenAPI specification: Upload `src/functions-sample/openapi.json`
5. Display name: `Sample API`
6. API URL suffix: `sample`
7. Click "Create"

### Via Script

```bash
# Set environment variables
export RESOURCE_GROUP="rg-apim-lab"
export APIM_NAME="apim-lab-yourname"
export API_ID="sample-api"
export API_PATH="sample"

# Run import script
./scripts/import-openapi.sh
```

## Step 4: Test the API

### Get Subscription Key

1. In APIM portal → Subscriptions
2. Find "Built-in all-access subscription"
3. Click "..." → "Show/hide keys"
4. Copy the primary key

### Test with cURL

```bash
# Replace with your values
APIM_URL="https://apim-lab-yourname.azure-api.net"
SUBSCRIPTION_KEY="your-subscription-key-here"

# Test GET request
curl "${APIM_URL}/sample/httpTrigger?name=Lab" \
  -H "Ocp-Apim-Subscription-Key: ${SUBSCRIPTION_KEY}"

# Expected response:
# {
#   "message": "Hello, Lab!",
#   "timestamp": "2024-01-01T12:00:00.000Z",
#   ...
# }
```

### Test with Postman

1. Import `tests/postman/collection.json`
2. Import `tests/postman/environment.json`
3. Update environment variables:
   - `gatewayUrl`: Your APIM gateway URL
   - `subscriptionKey`: Your subscription key
4. Run the collection

### Test with REST Client (VS Code)

1. Install REST Client extension in VS Code
2. Open `tests/rest-client/sample.http`
3. Set variables at the bottom
4. Click "Send Request" on any request

## Step 5: Apply Policies

### Add Rate Limiting

1. In APIM portal → APIs → Sample API
2. Select "All operations"
3. In the Inbound processing section, click `</>` (code editor)
4. Add this inside `<inbound>`:

```xml
<rate-limit calls="10" renewal-period="60" />
```

5. Save

### Test Rate Limiting

Run this command multiple times quickly:

```bash
for i in {1..15}; do
  curl "${APIM_URL}/sample/httpTrigger?name=RateTest" \
    -H "Ocp-Apim-Subscription-Key: ${SUBSCRIPTION_KEY}" \
    -w "\nStatus: %{http_code}\n"
done
```

After 10 requests, you should see `429 Too Many Requests`.

### Add Response Caching

1. In the same policy editor, in `<outbound>` section add:

```xml
<cache-store duration="300" />
```

2. In `<inbound>` section (before rate-limit) add:

```xml
<cache-lookup vary-by-developer="false" vary-by-developer-groups="false" />
```

3. Save

### Test Caching

```bash
# First request (cache miss)
curl -v "${APIM_URL}/sample/httpTrigger?name=Cache" \
  -H "Ocp-Apim-Subscription-Key: ${SUBSCRIPTION_KEY}" \
  2>&1 | grep "X-Cache"

# Second request (cache hit)
curl -v "${APIM_URL}/sample/httpTrigger?name=Cache" \
  -H "Ocp-Apim-Subscription-Key: ${SUBSCRIPTION_KEY}" \
  2>&1 | grep "X-Cache"
```

Second request should be faster and have `X-Cache: HIT` header.

## Step 6: View Logs and Metrics

### Application Insights

1. Navigate to your Application Insights resource
2. Go to "Logs"
3. Run this query:

```kusto
requests
| where timestamp > ago(1h)
| where cloud_RoleName contains "apim"
| project timestamp, name, resultCode, duration, operation_Name
| order by timestamp desc
| take 50
```

### APIM Metrics

1. In APIM portal → Monitoring → Metrics
2. Add metrics:
   - Requests (count)
   - Duration (avg)
   - Capacity (avg)
3. Time range: Last hour

### Log Analytics

1. Navigate to Log Analytics workspace
2. Logs → Run:

```kusto
ApiManagementGatewayLogs
| where TimeGenerated > ago(1h)
| project TimeGenerated, ApiId, Method, Url, ResponseCode, TotalTime
| order by TimeGenerated desc
```

## Step 7: Cleanup (Optional)

To avoid charges:

```bash
# Delete the entire resource group
az group delete --name rg-apim-lab --yes --no-wait
```

Or keep for further learning but be aware of costs (~$50/month for Developer tier).

## 🎓 What You Learned

- ✅ Deployed Azure API Management (Developer tier)
- ✅ Imported an API using OpenAPI specification
- ✅ Applied rate limiting policy
- ✅ Implemented response caching
- ✅ Tested APIs with multiple tools
- ✅ Viewed logs and metrics

## 📚 Next Steps

Continue to [Lab 2: Intermediate](../lab-02-intermediate/README.md) to learn about:
- Application Insights and Log Analytics integration
- JWT authentication with Azure AD
- Advanced rate limiting and quotas
- Load testing with k6
- KQL queries for observability

## 📖 Additional Resources

- [APIM Documentation](https://learn.microsoft.com/azure/api-management/)
- [Policy Reference](https://learn.microsoft.com/azure/api-management/api-management-policies)
- [Pricing](https://azure.microsoft.com/pricing/details/api-management/)

## ❓ Troubleshooting

**Issue**: Deployment taking too long
- **Solution**: APIM provisioning takes 30-45 minutes. Be patient!

**Issue**: 401 Unauthorized
- **Solution**: Check subscription key is correct and not expired

**Issue**: Can't see logs
- **Solution**: Ensure Application Insights is linked and wait 5-10 minutes for data

**Issue**: Rate limit not working
- **Solution**: Policy must be saved. Test with >10 requests within 60 seconds

---

**Congratulations!** You've completed your first APIM lab. 🎉
