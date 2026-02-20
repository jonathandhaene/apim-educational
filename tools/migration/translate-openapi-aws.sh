#!/bin/bash
#
# translate-openapi-aws.sh
#
# Translates and cleans OpenAPI specifications exported from AWS API Gateway
# for import into Azure API Management.
#
# Features:
#   - Removes AWS-specific extensions (x-amazon-*)
#   - Converts OpenAPI 2.0 (Swagger) specifications to OpenAPI 3.0
#   - Automatically generates operationId for operations that lack one
#   - Validates APIM-specific requirements (title, version, server URLs, security)
#
# Usage: ./translate-openapi-aws.sh <input-file> <output-file>
#
# Prerequisites:
#   - Python 3 with PyYAML (pip install pyyaml)
#   - Spectral CLI (optional, for linting): npm install -g @stoplight/spectral-cli
#
# See also:
#   - ../../docs/migration/aws-to-apim.md   (full migration guide)
#   - openapi_utils.py                      (core processing library)
#

set -euo pipefail

# Check arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <input-file> <output-file>"
    echo ""
    echo "Example:"
    echo "  $0 aws-api-export.yaml apim-api.yaml"
    echo ""
    echo "Export your API from AWS first:"
    echo "  aws apigateway get-export \\"
    echo "    --rest-api-id <api-id> --stage-name prod \\"
    echo "    --export-type oas30 --accepts application/yaml \\"
    echo "    > aws-api-export.yaml"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="$2"

# Resolve the directory of this script so we can locate openapi_utils.py
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found"
    exit 1
fi

echo "========================================="
echo "OpenAPI Translation Tool for APIM (AWS)"
echo "========================================="
echo "Input:  $INPUT_FILE"
echo "Output: $OUTPUT_FILE"
echo ""

# Step 1: Validate input with Spectral
echo "[1/4] Validating input OpenAPI spec..."
if command -v spectral &> /dev/null; then
    spectral lint "$INPUT_FILE" || {
        echo "Warning: Spectral validation found issues. Continuing anyway..."
    }
else
    echo "Warning: Spectral CLI not found. Skipping pre-validation."
    echo "Install with: npm install -g @stoplight/spectral-cli"
fi

# Step 2: Run openapi_utils.py (removes AWS extensions, converts Swagger→OAS3,
#         generates missing operationIds, validates APIM requirements)
echo "[2/4] Processing spec with openapi_utils.py (source: aws)..."
if command -v python3 &> /dev/null; then
    python3 "${SCRIPT_DIR}/openapi_utils.py" \
        "$INPUT_FILE" "$OUTPUT_FILE" \
        --source aws || {
        echo "Error: openapi_utils.py processing failed."
        exit 1
    }
else
    echo "Warning: python3 not found. Falling back to file copy."
    echo "Install Python 3 to enable automatic translation features:"
    echo "  - Swagger 2.0 → OpenAPI 3.0 conversion"
    echo "  - Automatic operationId generation"
    echo "  - APIM requirement validation"
    cp "$INPUT_FILE" "$OUTPUT_FILE"
fi

# Step 3: Validate output with Spectral
echo "[3/4] Validating output OpenAPI spec..."
if command -v spectral &> /dev/null; then
    spectral lint "$OUTPUT_FILE" || {
        echo "Warning: Output spec has validation issues."
    }
fi

# Step 4: Summary
echo "[4/4] Translation complete!"
echo ""
echo "Next steps:"
echo "  1. Review the output file: $OUTPUT_FILE"
echo "  2. Manually translate any AWS-specific policies:"
echo "     - Lambda authorizers  → validate-jwt or custom policies"
echo "     - Cognito User Pools  → validate-jwt (OpenID Connect)"
echo "     - Usage plans/API keys → APIM subscriptions"
echo "     - Stage variables      → APIM Named Values"
echo "  3. Import to APIM using: ../../scripts/import-openapi.sh"
echo ""
echo "Note: This is a helper script. Manual review is required!"
echo "      Refer to: ../../docs/migration/aws-to-apim.md"
