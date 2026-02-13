#!/bin/bash
#
# translate-openapi.sh
#
# Translates and cleans OpenAPI specifications from Google API Gateway/Apigee
# for import into Azure API Management.
#
# Usage: ./translate-openapi.sh <input-file> <output-file>
#

set -e

# Check arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <input-file> <output-file>"
    echo ""
    echo "Example:"
    echo "  $0 google-api.yaml apim-api.yaml"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="$2"

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found"
    exit 1
fi

echo "========================================="
echo "OpenAPI Translation Tool for APIM"
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
    echo "Warning: Spectral CLI not found. Skipping validation."
    echo "Install with: npm install -g @stoplight/spectral-cli"
fi

# Step 2: Clean Google-specific extensions
echo "[2/4] Removing Google-specific extensions..."

# TODO: Implement actual transformation logic
# This is a placeholder - actual implementation would:
# - Parse YAML/JSON
# - Remove x-google-* extensions
# - Normalize paths and operations
# - Add APIM-compatible metadata
# - Handle security schemes

# For now, just copy the file as a starting point
cp "$INPUT_FILE" "$OUTPUT_FILE"

echo "TODO: Implement the following transformations:"
echo "  - Remove x-google-backend extensions"
echo "  - Remove x-google-management extensions"
echo "  - Convert x-google-quota to APIM policy"
echo "  - Normalize security schemes"
echo "  - Ensure operationId uniqueness"
echo ""

# Step 3: Validate output
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
echo "  2. Manually translate any Google-specific policies"
echo "  3. Import to APIM using: ../../scripts/import-openapi.sh"
echo ""
echo "Note: This is a helper script. Manual review is required!"
echo "      Refer to: ../../docs/migration/google-to-apim.md"
echo ""

# Actual implementation notes:
# ========================================
# To properly implement this script, you would need to:
#
# 1. Parse YAML/JSON using yq, jq, or Python
# 2. Remove Google-specific extensions:
#    - x-google-backend
#    - x-google-management
#    - x-google-quota
#    - x-google-allow
#    - x-google-endpoints
#
# 3. Transform security schemes:
#    - API key locations (query vs header)
#    - OAuth flows
#    - JWT validation parameters
#
# 4. Normalize operation IDs:
#    - Ensure uniqueness
#    - Follow APIM naming conventions
#
# 5. Add APIM-specific extensions if needed:
#    - x-apim-operations
#    - x-apim-policies (though policies should be separate)
#
# Example with yq:
#   yq eval 'del(.paths.*.*.x-google-backend)' "$INPUT_FILE" > "$OUTPUT_FILE"
#
# Example with Python:
#   python3 << 'PYEOF'
#   import yaml
#   import sys
#   
#   with open(sys.argv[1], 'r') as f:
#       spec = yaml.safe_load(f)
#   
#   # Remove Google extensions
#   for path in spec.get('paths', {}).values():
#       for operation in path.values():
#           if isinstance(operation, dict):
#               keys_to_remove = [k for k in operation.keys() if k.startswith('x-google-')]
#               for key in keys_to_remove:
#                   del operation[key]
#   
#   with open(sys.argv[2], 'w') as f:
#       yaml.dump(spec, f, default_flow_style=False)
#   PYEOF
#
# For production use, implement the above logic or use a more sophisticated
# tool like OpenAPI generators with custom templates.
