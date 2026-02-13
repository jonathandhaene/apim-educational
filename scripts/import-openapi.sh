#!/bin/bash
# Import OpenAPI specification into Azure API Management

set -e

# TODO: Replace with your values or pass as parameters
RESOURCE_GROUP="${RESOURCE_GROUP:-rg-apim-dev}"
APIM_NAME="${APIM_NAME:-apim-dev}"
API_ID="${API_ID:-sample-api}"
API_PATH="${API_PATH:-sample}"
OPENAPI_FILE="${OPENAPI_FILE:-src/functions-sample/openapi.json}"

echo "=== Importing OpenAPI to APIM ==="
echo "APIM: $APIM_NAME"
echo "API ID: $API_ID"
echo "Path: $API_PATH"
echo "OpenAPI: $OPENAPI_FILE"
echo ""

# Check if logged in
if ! az account show &> /dev/null; then
  echo "Error: Not logged in. Run: az login"
  exit 1
fi

# Import API
az apim api import \
  --resource-group "$RESOURCE_GROUP" \
  --service-name "$APIM_NAME" \
  --path "$API_PATH" \
  --api-id "$API_ID" \
  --specification-format OpenApi \
  --specification-path "$OPENAPI_FILE" \
  --display-name "Sample API" \
  --protocols https

echo ""
echo "API imported successfully!"
echo "Test at: https://$APIM_NAME.azure-api.net/$API_PATH"
