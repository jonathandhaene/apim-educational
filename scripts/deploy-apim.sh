#!/bin/bash
# Deploy Azure API Management using Bicep
# Updated for 2026 best practices

set -euo pipefail

# Default values
RESOURCE_GROUP=""
LOCATION="eastus"
PARAM_FILE="infra/bicep/params/public-dev.bicepparam"
WHAT_IF=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -g|--resource-group)
      RESOURCE_GROUP="$2"
      shift 2
      ;;
    -l|--location)
      LOCATION="$2"
      shift 2
      ;;
    -p|--param-file)
      PARAM_FILE="$2"
      shift 2
      ;;
    --what-if)
      WHAT_IF=true
      shift
      ;;
    -h|--help)
      echo "Usage: ./deploy-apim.sh -g <resource-group> [-l <location>] [-p <param-file>] [--what-if]"
      echo ""
      echo "Options:"
      echo "  -g, --resource-group  Resource group name (required)"
      echo "  -l, --location        Azure region (default: eastus)"
      echo "  -p, --param-file      Parameter file path (default: infra/bicep/params/public-dev.bicepparam)"
      echo "  --what-if             Run what-if analysis without deploying"
      echo "  -h, --help            Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use -h or --help for usage information"
      exit 1
      ;;
  esac
done

# Validate required parameters
if [ -z "$RESOURCE_GROUP" ]; then
  echo "Error: Resource group name is required"
  echo "Use: ./deploy-apim.sh -g <resource-group>"
  exit 1
fi

echo "=== Azure API Management Deployment ==="
echo "Resource Group: $RESOURCE_GROUP"
echo "Location: $LOCATION"
echo "Parameter File: $PARAM_FILE"
echo ""

# Check if logged in
if ! az account show &> /dev/null; then
  echo "Not logged in to Azure. Please run: az login"
  exit 1
fi

# Create resource group if it doesn't exist
if ! az group show --name "$RESOURCE_GROUP" &> /dev/null; then
  echo "Creating resource group $RESOURCE_GROUP..."
  az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
fi

# Run what-if or deploy
if [ "$WHAT_IF" = true ]; then
  echo "Running what-if analysis..."
  az deployment group what-if \
    --resource-group "$RESOURCE_GROUP" \
    --template-file infra/bicep/main.bicep \
    --parameters "$PARAM_FILE"
else
  echo "Deploying APIM..."
  az deployment group create \
    --resource-group "$RESOURCE_GROUP" \
    --template-file infra/bicep/main.bicep \
    --parameters "$PARAM_FILE" \
    --verbose
  
  echo ""
  echo "=== Deployment Complete ==="
  echo "Retrieve outputs:"
  echo "  az deployment group show -g $RESOURCE_GROUP -n main --query properties.outputs"
fi
