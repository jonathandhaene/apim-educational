# Twilio SMS Integration

This Azure Function demonstrates integration with Twilio's SMS API for sending text messages. It includes security best practices for handling credentials and input validation.

## Features

- SMS Sending using Twilio API
- Environment Variables for secure credential management
- Input Validation for phone numbers and messages
- Comprehensive Error Handling and logging
- Unit Tests with mocked Twilio client
- TypeScript implementation

## Prerequisites

- Node.js 18.x or later
- Azure Functions Core Tools v4
- [Twilio Account](https://www.twilio.com/try-twilio) (free trial available)
- Azure CLI

## Quick Start

### 1. Twilio Account Setup

1. Sign up at https://www.twilio.com/try-twilio
2. Get credentials from Twilio Console:
   - Account SID
   - Auth Token
   - Phone Number

### 2. Configure Environment

Create `local.settings.json`:

```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "node",
    "TWILIO_ACCOUNT_SID": "ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
    "TWILIO_AUTH_TOKEN": "your_auth_token_here",
    "TWILIO_FROM_NUMBER": "+15551234567"
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
curl -X POST "http://localhost:7071/api/sendSMS" \
  -H "Content-Type: application/json" \
  -d '{"to": "+15559876543", "message": "Hello from Azure!"}'
```

## API Reference

### POST /api/sendSMS

**Request:**
```json
{
  "to": "+15559876543",
  "message": "Your message here"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "messageSid": "SM...",
  "status": "queued",
  "to": "+15559876543",
  "from": "+15551234567",
  "timestamp": "2024-01-01T12:00:00.000Z"
}
```

## Deploy to Azure with Key Vault

```bash
# Create resources
az group create --name rg-twilio --location eastus
az keyvault create --name kv-twilio --resource-group rg-twilio --location eastus
az functionapp create --name func-twilio-sms --resource-group rg-twilio \
  --storage-account sttwilio --consumption-plan-location eastus \
  --runtime node --runtime-version 18 --functions-version 4

# Enable managed identity
az functionapp identity assign --name func-twilio-sms --resource-group rg-twilio

# Grant Key Vault access
PRINCIPAL_ID=$(az functionapp identity show --name func-twilio-sms \
  --resource-group rg-twilio --query principalId -o tsv)
az keyvault set-policy --name kv-twilio --object-id $PRINCIPAL_ID \
  --secret-permissions get list

# Add secrets
az keyvault secret set --vault-name kv-twilio --name TwilioAccountSid --value "AC..."
az keyvault secret set --vault-name kv-twilio --name TwilioAuthToken --value "..."
az keyvault secret set --vault-name kv-twilio --name TwilioFromNumber --value "+1..."

# Configure app settings
az functionapp config appsettings set --name func-twilio-sms \
  --resource-group rg-twilio --settings \
  TWILIO_ACCOUNT_SID="@Microsoft.KeyVault(VaultName=kv-twilio;SecretName=TwilioAccountSid)" \
  TWILIO_AUTH_TOKEN="@Microsoft.KeyVault(VaultName=kv-twilio;SecretName=TwilioAuthToken)" \
  TWILIO_FROM_NUMBER="@Microsoft.KeyVault(VaultName=kv-twilio;SecretName=TwilioFromNumber)"

# Deploy
func azure functionapp publish func-twilio-sms
```

## Security Best Practices

### Credential Management
- ✅ Store in Azure Key Vault
- ✅ Use managed identities
- ✅ Rotate credentials regularly
- ❌ Never commit to source control

### Input Validation
- ✅ Validate phone format (E.164)
- ✅ Sanitize message content
- ✅ Limit message length
- ✅ Use TypeScript for type safety

### Rate Limiting with APIM
```xml
<rate-limit calls="100" renewal-period="60" />
<quota calls="10000" renewal-period="2592000" />
```

## Testing

```bash
npm test
```

## Troubleshooting

**Issue**: "Twilio configuration is missing"
- Ensure environment variables are set

**Issue**: "Invalid phone number format"
- Use E.164 format: +15551234567

**Issue**: "The number is unverified" (Trial)
- Verify numbers in Twilio Console or upgrade

## Resources

- [Twilio SMS Docs](https://www.twilio.com/docs/sms)
- [Azure Functions](https://learn.microsoft.com/azure/azure-functions/)
- [Azure Key Vault](https://learn.microsoft.com/azure/key-vault/)
