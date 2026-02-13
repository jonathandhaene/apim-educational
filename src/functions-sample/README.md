# Sample Azure Function for APIM

This is a simple HTTP-triggered Azure Function that serves as a backend API for Azure API Management demonstrations.

## Features

- HTTP GET and POST endpoints
- OpenAPI 3.0 specification
- TypeScript implementation
- Ready to import into APIM

## Prerequisites

- [Node.js](https://nodejs.org/) 18.x or later
- [Azure Functions Core Tools](https://docs.microsoft.com/azure/azure-functions/functions-run-local) v4
- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)

## Local Development

```bash
# Install dependencies
npm install

# Run locally
npm start
```

Function will be available at `http://localhost:7071/api/httpTrigger`

## Test Locally

```bash
# GET request
curl "http://localhost:7071/api/httpTrigger?name=Alice"

# POST request
curl -X POST "http://localhost:7071/api/httpTrigger" \
  -H "Content-Type: text/plain" \
  -d "Bob"
```

## Deploy to Azure

```bash
# Login
az login

# Create resource group
az group create --name rg-functions --location eastus

# Create storage account
az storage account create \
  --name stfunctionsample \
  --resource-group rg-functions \
  --location eastus \
  --sku Standard_LRS

# Create Function App
az functionapp create \
  --resource-group rg-functions \
  --name sample-api-function \
  --storage-account stfunctionsample \
  --consumption-plan-location eastus \
  --runtime node \
  --runtime-version 18 \
  --functions-version 4

# Deploy
func azure functionapp publish sample-api-function
```

## Import to APIM

### Option 1: Azure Portal

1. Navigate to APIM → APIs
2. Click "+ Add API"
3. Select "Function App"
4. Browse and select your Function App
5. Import

### Option 2: Azure CLI

```bash
az apim api import \
  --resource-group rg-apim \
  --service-name apim-instance \
  --path /sample \
  --api-id sample-api \
  --specification-format OpenApi \
  --specification-path openapi.json \
  --display-name "Sample API"
```

### Option 3: Script

See `../../scripts/import-openapi.sh` for automated import.

## OpenAPI Specification

The `openapi.json` file describes the API contract and can be:
- Imported directly into APIM
- Used for client SDK generation
- Used for API documentation
- Validated with Spectral linter

## Testing in APIM

Once imported:

1. Get subscription key from APIM portal
2. Test via APIM gateway:

```bash
curl "https://apim-instance.azure-api.net/sample/httpTrigger?name=Test" \
  -H "Ocp-Apim-Subscription-Key: YOUR_KEY"
```

## Next Steps

- Apply policies (see `../../policies/`)
- Add to product
- Configure caching
- Set up monitoring
- Test with Postman collection (see `../../tests/postman/`)
