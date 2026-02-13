#!/bin/bash
# translate-openapi-aws.sh
# Translate AWS API Gateway OpenAPI specification to APIM-compatible format
#
# This script removes AWS-specific extensions and prepares the OpenAPI spec
# for import into Azure API Management.
#
# Usage: ./translate-openapi-aws.sh input.json output.json

set -e

# Check for required arguments
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <input-openapi.json> <output-openapi.json>"
  echo ""
  echo "Example:"
  echo "  $0 aws-api-export.json apim-ready-api.json"
  exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="$2"

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
  echo "Error: Input file '$INPUT_FILE' not found"
  exit 1
fi

# Check for jq
if ! command -v jq &> /dev/null; then
  echo "Error: jq is required but not installed."
  echo ""
  echo "Install jq using:"
  echo "  Ubuntu/Debian: sudo apt-get install jq"
  echo "  macOS: brew install jq"
  echo "  RHEL/CentOS: sudo yum install jq"
  exit 1
fi

echo "=== AWS to APIM OpenAPI Translator ==="
echo "Input:  $INPUT_FILE"
echo "Output: $OUTPUT_FILE"
echo ""

# TODO: Implement comprehensive AWS extension removal
# This is a stub implementation showing the structure

# Basic translation using jq
# Remove x-amazon-apigateway-* extensions at all levels
jq '
  # Remove AWS extensions from root level
  del(.."x-amazon-apigateway-any-method") |
  del(.."x-amazon-apigateway-api-key-source") |
  del(.."x-amazon-apigateway-binary-media-types") |
  del(.."x-amazon-apigateway-cors") |
  del(.."x-amazon-apigateway-gateway-responses") |
  del(.."x-amazon-apigateway-policy") |
  del(.."x-amazon-apigateway-importexport-version") |
  
  # Remove AWS extensions from operations
  walk(
    if type == "object" then
      del(.["x-amazon-apigateway-integration"]) |
      del(.["x-amazon-apigateway-request-validator"]) |
      del(.["x-amazon-apigateway-request-validators"]) |
      del(.["x-amazon-apigateway-authorizer"])
    else
      .
    end
  )
' "$INPUT_FILE" > "$OUTPUT_FILE"

echo "✓ Translation complete"
echo ""
echo "Next steps:"
echo "  1. Review the output file: $OUTPUT_FILE"
echo "  2. Add APIM-specific metadata (servers, security schemes)"
echo "  3. Validate with Spectral: spectral lint $OUTPUT_FILE --ruleset .spectral.yaml"
echo "  4. Import to APIM: ./scripts/import-openapi.sh"
echo ""
echo "TODO: Customize this script to handle:"
echo "  - Convert stage variables (e.g., \${stageVariables.backendUrl}) to Named Values"
echo "  - Map AWS integration types to APIM backends"
echo "  - Preserve any custom x-* extensions you need"
echo "  - Add appropriate APIM security schemes"
echo ""
echo "For more details, see: docs/migration/aws-to-apim.md"
