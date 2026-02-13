# Stripe Payment Integration

This Azure Function demonstrates integration with Stripe's Payment API for processing secure payments. It includes security best practices with Azure Key Vault integration.

## Features

- Payment Processing using Stripe Payment Intents API
- Azure Key Vault integration for secure credential management
- Input Validation for amounts and currencies
- Comprehensive Error Handling for Stripe errors
- Unit Tests with mocked Stripe client
- TypeScript implementation with strong typing

## Prerequisites

- Node.js 18.x or later
- Azure Functions Core Tools v4
- [Stripe Account](https://dashboard.stripe.com/register) (free)
- Azure CLI
- Azure Key Vault (recommended for production)

## Quick Start

### 1. Stripe Account Setup

1. Sign up at https://dashboard.stripe.com/register
2. Get API keys from Dashboard → Developers → API keys:
   - **Test Mode**: Use test keys (starts with `sk_test_`)
   - **Live Mode**: Use live keys only in production

### 2. Configure Environment

Create `local.settings.json`:

```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "node",
    "STRIPE_SECRET_KEY": "sk_test_xxxxxxxxxxxxxxxxxxxx"
  }
}
```

**Important**: Add `local.settings.json` to `.gitignore`!

### 3. Install and Run

```bash
npm install
npm start
```

### 4. Test

```bash
# Test with Stripe test card (4242 4242 4242 4242)
curl -X POST "http://localhost:7071/api/processPayment" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 1000,
    "currency": "USD",
    "paymentMethodId": "pm_card_visa",
    "description": "Test payment"
  }'
```

## API Reference

### POST /api/processPayment

**Request:**
```json
{
  "amount": 1000,
  "currency": "USD",
  "paymentMethodId": "pm_card_visa",
  "description": "Optional description",
  "metadata": {
    "orderId": "12345",
    "customerId": "user_123"
  }
}
```

**Fields:**
- `amount` (required): Amount in cents (1000 = $10.00)
- `currency` (required): ISO 3-letter code (USD, EUR, GBP)
- `paymentMethodId` (required): Stripe payment method ID
- `description` (optional): Payment description
- `metadata` (optional): Custom key-value pairs

**Success Response (200):**
```json
{
  "success": true,
  "paymentIntentId": "pi_...",
  "status": "succeeded",
  "amount": 1000,
  "currency": "usd",
  "created": 1234567890,
  "timestamp": "2024-01-01T12:00:00.000Z"
}
```

**Error Response (402 - Card Declined):**
```json
{
  "success": false,
  "error": "Card was declined",
  "code": "card_declined",
  "decline_code": "generic_decline"
}
```

## Deploy to Azure with Key Vault

```bash
# Create resources
az group create --name rg-stripe --location eastus
az keyvault create --name kv-stripe --resource-group rg-stripe --location eastus
az storage account create --name ststripe --resource-group rg-stripe --sku Standard_LRS
az functionapp create --name func-stripe-payment --resource-group rg-stripe \
  --storage-account ststripe --consumption-plan-location eastus \
  --runtime node --runtime-version 18 --functions-version 4

# Enable managed identity
az functionapp identity assign --name func-stripe-payment --resource-group rg-stripe

# Grant Key Vault access
PRINCIPAL_ID=$(az functionapp identity show --name func-stripe-payment \
  --resource-group rg-stripe --query principalId -o tsv)
az keyvault set-policy --name kv-stripe --object-id $PRINCIPAL_ID \
  --secret-permissions get list

# Add Stripe secret
az keyvault secret set --vault-name kv-stripe \
  --name StripeSecretKey --value "sk_live_xxxx"

# Configure app settings
az functionapp config appsettings set --name func-stripe-payment \
  --resource-group rg-stripe --settings \
  STRIPE_SECRET_KEY="@Microsoft.KeyVault(VaultName=kv-stripe;SecretName=StripeSecretKey)"

# Deploy
func azure functionapp publish func-stripe-payment
```

## Security Best Practices

### 1. Credential Management
- ✅ Store API keys in Azure Key Vault
- ✅ Use managed identities
- ✅ Use test keys in development
- ✅ Rotate keys periodically
- ❌ Never commit keys to source control
- ❌ Never log sensitive data

### 2. PCI Compliance
- ✅ Never handle raw card data
- ✅ Use Stripe.js on frontend for card collection
- ✅ Use Payment Method IDs instead of card details
- ❌ Never store card numbers

### 3. Input Validation
- ✅ Validate amount (positive, integer, in cents)
- ✅ Validate currency format
- ✅ Validate payment method ID
- ✅ Use TypeScript for type safety

### 4. Error Handling
- ✅ Handle Stripe-specific errors
- ✅ Return appropriate HTTP status codes
- ❌ Don't expose internal details to clients

### 5. Rate Limiting with APIM

```xml
<policies>
  <inbound>
    <!-- Authentication -->
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
  </inbound>
  <backend>
    <forward-request />
  </backend>
  <outbound>
    <!-- Remove sensitive headers -->
    <set-header name="X-Stripe-Client-User-Agent" exists-action="delete" />
  </outbound>
</policies>
```

## Testing

### Run Unit Tests

```bash
npm test
```

### Stripe Test Cards

Use these test cards in test mode:

| Card Number | Description |
|-------------|-------------|
| 4242 4242 4242 4242 | Succeeds |
| 4000 0000 0000 9995 | Declined (insufficient funds) |
| 4000 0000 0000 0002 | Declined (generic) |
| 4000 0025 0000 3155 | Requires authentication |

**Important**: Use any future expiry date and any 3-digit CVC.

## Integration Examples

### Frontend (React/Angular)

```typescript
// 1. Collect payment method using Stripe.js
const stripe = await loadStripe('pk_test_xxx');
const { paymentMethod } = await stripe.createPaymentMethod({
  type: 'card',
  card: cardElement,
});

// 2. Call Azure Function via APIM
const response = await fetch('https://apim.azure-api.net/payments/processPayment', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Ocp-Apim-Subscription-Key': 'your-key'
  },
  body: JSON.stringify({
    amount: 1000,
    currency: 'USD',
    paymentMethodId: paymentMethod.id,
    description: 'Purchase from web app'
  })
});

const result = await response.json();
```

## Monitoring

### Application Insights KQL Queries

```kusto
// Failed payments
requests
| where name == "processPayment"
| where success == false
| project timestamp, resultCode, duration

// Payment success rate
requests
| where name == "processPayment"
| summarize 
    Total = count(),
    Success = countif(success == true),
    Failed = countif(success == false)
| extend SuccessRate = (Success * 100.0) / Total

// Average payment amount
traces
| where message contains "Payment processed successfully"
| extend amount = extract(@"Intent ID: (pi_\w+)", 1, message)
| summarize avg_amount = avg(toint(amount))
```

## Webhooks (Optional)

For handling async payment events:

```typescript
// webhook.ts
import { app, HttpRequest, HttpResponseInit, InvocationContext } from '@azure/functions';
import Stripe from 'stripe';

export async function stripeWebhook(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
    const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);
    const sig = request.headers.get('stripe-signature');
    const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

    try {
        const body = await request.text();
        const event = stripe.webhooks.constructEvent(body, sig!, webhookSecret!);

        switch (event.type) {
            case 'payment_intent.succeeded':
                // Handle successful payment
                break;
            case 'payment_intent.payment_failed':
                // Handle failed payment
                break;
        }

        return { status: 200 };
    } catch (err) {
        return { status: 400, jsonBody: { error: err.message } };
    }
}
```

## Troubleshooting

**Issue**: "Stripe configuration is missing"
- Ensure `STRIPE_SECRET_KEY` environment variable is set

**Issue**: "Invalid request to Stripe"
- Check payment method ID format
- Verify test/live mode matches your API key

**Issue**: "Card was declined"
- Use test cards in test mode
- Check card details are correct
- Review Stripe Dashboard for decline reason

## Cost Considerations

### Stripe Pricing (as of 2024)
- **Standard**: 2.9% + $0.30 per successful card charge
- **International**: +1.5% for cards outside US
- **Currency conversion**: +1% for currency conversion

### Azure Costs
- **Function App (Consumption)**: Pay per execution
- **Key Vault**: ~$0.03 per 10,000 operations
- **Storage**: Minimal for function logs

## Next Steps

- Implement webhook handling for async events
- Add refund functionality
- Implement subscription billing
- Add support for alternative payment methods (ACH, SEPA)
- Set up fraud detection

## Resources

- [Stripe API Documentation](https://stripe.com/docs/api)
- [Stripe Node.js SDK](https://github.com/stripe/stripe-node)
- [Azure Functions](https://learn.microsoft.com/azure/azure-functions/)
- [Azure Key Vault](https://learn.microsoft.com/azure/key-vault/)
- [PCI Compliance](https://stripe.com/docs/security/guide)

## License

This sample is part of the Azure APIM Educational Repository and follows the same license.
