# Third-Party API Integrations

This directory contains Azure Functions demonstrating secure integration with popular third-party APIs. Each example includes security best practices and Azure Key Vault integration.

## Available Integrations

### [Twilio SMS](twilio-sms/)

Send SMS messages using Twilio's API.

**Features:**
- Phone number validation (E.164 format)
- Environment variable configuration
- Azure Key Vault integration
- Comprehensive error handling
- Unit tests with mocked Twilio client

**Quick Start:**
```bash
cd twilio-sms
npm install
# Configure local.settings.json with Twilio credentials
npm start
```

**API Endpoint:** `POST /api/sendSMS`

### [Stripe Payments](stripe-payment/)

Process secure payments using Stripe's Payment Intents API.

**Features:**
- PCI-compliant payment processing
- Azure Key Vault for API keys
- Input validation (amount, currency)
- Stripe error handling
- Unit tests with mocked Stripe client

**Quick Start:**
```bash
cd stripe-payment
npm install
# Configure local.settings.json with Stripe key
npm start
```

**API Endpoint:** `POST /api/processPayment`

## Architecture

```
Client App → APIM → Azure Function → Third-Party API
                ↓
         Azure Key Vault (credentials)
```

## Security Best Practices

### Credential Management

✅ **DO:**
- Store API keys in Azure Key Vault
- Use managed identities for Azure resources
- Rotate credentials regularly
- Use test/sandbox keys in development
- Add `local.settings.json` to `.gitignore`

❌ **DON'T:**
- Commit credentials to source control
- Hardcode API keys in code
- Share credentials via insecure channels
- Use production keys in development

### Key Vault Setup

```bash
# Create Key Vault
az keyvault create --name kv-integrations --resource-group my-rg --location eastus

# Enable managed identity on Function App
az functionapp identity assign --name my-function --resource-group my-rg

# Grant Key Vault access
PRINCIPAL_ID=$(az functionapp identity show --name my-function \
  --resource-group my-rg --query principalId -o tsv)
az keyvault set-policy --name kv-integrations --object-id $PRINCIPAL_ID \
  --secret-permissions get list

# Add secrets
az keyvault secret set --vault-name kv-integrations --name ApiKey --value "xxx"

# Configure Function App
az functionapp config appsettings set --name my-function --resource-group my-rg \
  --settings API_KEY="@Microsoft.KeyVault(VaultName=kv-integrations;SecretName=ApiKey)"
```

### Input Validation

All integrations include:
- ✅ Required field validation
- ✅ Format validation (phone, email, currency, etc.)
- ✅ Range validation (amounts, lengths)
- ✅ Type safety with TypeScript

### Error Handling

Each integration handles:
- ✅ Missing configuration
- ✅ Invalid input
- ✅ API-specific errors
- ✅ Network failures
- ✅ Rate limiting

## APIM Integration

### Import Functions to APIM

```bash
az apim api import \
  --resource-group my-rg \
  --service-name my-apim \
  --path /integrations \
  --api-id third-party-apis \
  --function-app my-function \
  --display-name "Third-Party Integrations"
```

### Apply Security Policies

```xml
<policies>
  <inbound>
    <!-- JWT validation -->
    <validate-jwt header-name="Authorization">
      <openid-config url="https://login.microsoftonline.com/{tenant}/.well-known/openid-configuration" />
    </validate-jwt>
    
    <!-- Rate limiting -->
    <rate-limit calls="100" renewal-period="60" />
    <quota calls="10000" renewal-period="2592000" />
    
    <!-- Input validation -->
    <validate-content unspecified-content-type-action="prevent" 
                      max-size="102400" 
                      size-limit-exceeded-action="prevent" />
    
    <!-- Remove client headers before forwarding -->
    <set-header name="X-Client-IP" exists-action="delete" />
  </inbound>
  
  <backend>
    <forward-request />
  </backend>
  
  <outbound>
    <!-- Remove sensitive response headers -->
    <set-header name="X-API-Version" exists-action="delete" />
    <set-header name="X-RateLimit-Remaining" exists-action="delete" />
  </outbound>
  
  <on-error>
    <!-- Don't expose internal errors -->
    <set-body>@{
      return new JObject(
        new JProperty("error", "An error occurred processing your request"),
        new JProperty("traceId", context.RequestId)
      ).ToString();
    }</set-body>
  </on-error>
</policies>
```

## Testing

Each integration includes unit tests:

```bash
# Twilio
cd twilio-sms
npm test

# Stripe
cd stripe-payment
npm test
```

## Monitoring

### Application Insights

Enable Application Insights for each Function App:

```bash
az monitor app-insights component create \
  --app my-insights \
  --location eastus \
  --resource-group my-rg

INSTRUMENTATION_KEY=$(az monitor app-insights component show \
  --app my-insights \
  --resource-group my-rg \
  --query instrumentationKey -o tsv)

az functionapp config appsettings set \
  --name my-function \
  --resource-group my-rg \
  --settings APPINSIGHTS_INSTRUMENTATIONKEY=$INSTRUMENTATION_KEY
```

### Key Metrics to Monitor

- **Success Rate**: Percentage of successful API calls
- **Latency**: Response time for third-party API calls
- **Error Rate**: Failed requests by error type
- **Cost**: API usage costs (per provider)
- **Rate Limit**: Approaching API rate limits

### Sample KQL Queries

```kusto
// API success rate
requests
| where name in ("sendSMS", "processPayment")
| summarize 
    Total = count(),
    Success = countif(success == true),
    Failed = countif(success == false)
  by name
| extend SuccessRate = (Success * 100.0) / Total

// Average response time
requests
| where name in ("sendSMS", "processPayment")
| summarize avg(duration) by name, bin(timestamp, 5m)

// Error breakdown
requests
| where name in ("sendSMS", "processPayment") and success == false
| summarize count() by resultCode, name
```

## Cost Management

### Twilio
- **SMS (US)**: ~$0.0079 per message
- **SMS (International)**: Varies by country
- **Phone Number**: ~$1.15/month

### Stripe
- **Standard**: 2.9% + $0.30 per successful charge
- **International**: +1.5%
- **Currency conversion**: +1%

### Azure
- **Function App**: Pay per execution
- **Key Vault**: ~$0.03 per 10,000 operations
- **Application Insights**: Based on data ingested

### Cost Optimization Tips

1. **Implement caching** for idempotent operations
2. **Use rate limiting** to prevent abuse
3. **Monitor usage** with alerts
4. **Use test/sandbox modes** in development
5. **Batch operations** where supported

## Deployment

### Deploy All Functions

```bash
# Navigate to each directory and deploy
cd twilio-sms
func azure functionapp publish func-twilio-sms

cd ../stripe-payment
func azure functionapp publish func-stripe-payment
```

### CI/CD with GitHub Actions

```yaml
name: Deploy Functions
on:
  push:
    branches: [main]
    paths:
      - 'src/third-party-integrations/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-node@v2
        with:
          node-version: '18'
      
      - name: Deploy Twilio Function
        run: |
          cd src/third-party-integrations/twilio-sms
          npm install
          npm run build
          func azure functionapp publish func-twilio-sms
        env:
          AZURE_CREDENTIALS: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Deploy Stripe Function
        run: |
          cd src/third-party-integrations/stripe-payment
          npm install
          npm run build
          func azure functionapp publish func-stripe-payment
        env:
          AZURE_CREDENTIALS: ${{ secrets.AZURE_CREDENTIALS }}
```

## Adding New Integrations

When adding a new third-party API integration:

1. **Create Directory**: `mkdir new-api-name`
2. **Add Package Files**: `package.json`, `tsconfig.json`, `host.json`
3. **Implement Function**: Follow existing patterns
4. **Add Tests**: Include unit tests with mocked API
5. **Document Setup**: Create comprehensive README
6. **Security**: Use Key Vault for credentials
7. **Error Handling**: Handle API-specific errors
8. **Input Validation**: Validate all inputs

## Troubleshooting

### "Configuration is missing" Error

**Solution**: Ensure environment variables are set:
- Check `local.settings.json` for local development
- Verify App Settings for deployed functions
- Confirm Key Vault secrets exist

### API Authentication Failed

**Solution**:
- Verify API keys are correct
- Check test vs. production mode
- Ensure managed identity has Key Vault access

### Rate Limiting Issues

**Solution**:
- Implement exponential backoff
- Add APIM rate limiting policies
- Monitor usage in provider dashboard

## Resources

- [Azure Functions Documentation](https://learn.microsoft.com/azure/azure-functions/)
- [Azure Key Vault](https://learn.microsoft.com/azure/key-vault/)
- [Azure API Management](https://learn.microsoft.com/azure/api-management/)
- [Twilio API Docs](https://www.twilio.com/docs)
- [Stripe API Docs](https://stripe.com/docs/api)

## License

These samples are part of the Azure APIM Educational Repository.
