# Migration Tools for Google API to Azure APIM

This directory contains scripts and utilities to assist with migrating from Google's API services (Apigee, Cloud API Gateway) to Azure API Management.

## Overview

Migration from Google API services to Azure APIM involves:
1. **Assessment**: Inventory APIs, policies, configurations
2. **Translation**: Convert OpenAPI specs and policies
3. **Import**: Load APIs and configurations into APIM
4. **Validation**: Test and verify functionality
5. **Cutover**: Switch traffic to APIM

## Tools Provided

### 1. OpenAPI Translation Scripts

**Purpose**: Clean, lint, and prepare OpenAPI specifications for APIM import.

#### translate-openapi.sh (Bash)

```bash
# Usage
./translate-openapi.sh input.yaml output.yaml

# What it does:
# - Validates OpenAPI spec with Spectral
# - Removes Google-specific extensions
# - Normalizes paths and operations
# - Ensures APIM compatibility
```

#### translate-openapi.ps1 (PowerShell)

```powershell
# Usage
.\translate-openapi.ps1 -InputFile input.yaml -OutputFile output.yaml

# What it does:
# - Same as Bash version, for Windows environments
# - PowerShell-native implementation
```

### 2. Policy Translation Guidance

**Manual Translation Required**: Policy translation cannot be fully automated due to semantic differences between platforms. Use the [Google to APIM Migration Guide](../../docs/migration/google-to-apim.md) for policy mapping.

**Process**:
1. Export Apigee/API Gateway policies
2. Identify equivalent APIM policies (see mapping table)
3. Rewrite using APIM policy syntax
4. Test thoroughly in non-production

**Example Policy Mapping**:

| Google Apigee | Azure APIM | Notes |
|---------------|------------|-------|
| VerifyAPIKey | subscription-required | Auto-validated |
| OAuthV2 | validate-jwt | JWT validation |
| Quota | quota-by-key | Time-based limits |
| SpikeArrest | rate-limit-by-key | Rate smoothing |
| ResponseCache | cache-lookup/store | Response caching |

## Using the Tools

### Prerequisites

**For OpenAPI Translation:**
- Node.js 16+ (for Spectral)
- Bash or PowerShell
- [Spectral CLI](https://github.com/stoplightio/spectral):
  ```bash
  npm install -g @stoplight/spectral-cli
  ```

**For API Import:**
- Azure CLI installed and authenticated
- APIM instance deployed
- Appropriate permissions on the APIM resource

### Workflow

#### Step 1: Export from Google

**Apigee:**
```bash
# Export API proxy
apigee-cli apis export -o your-org -n your-api -f your-api.zip

# Extract OpenAPI if embedded
unzip your-api.zip
# Look for swagger.json or openapi.yaml in extracted files
```

**Google Cloud API Gateway:**
```bash
# Export API config
gcloud api-gateway api-configs describe CONFIG_NAME \
  --api=API_NAME \
  --format=json | jq '.openapiDocuments[0].document' > openapi.yaml
```

#### Step 2: Translate OpenAPI Spec

```bash
cd tools/migration

# Lint the original spec
spectral lint --ruleset ../../.spectral.yaml original-openapi.yaml

# Translate and clean
./translate-openapi.sh original-openapi.yaml cleaned-openapi.yaml

# Verify the output
spectral lint --ruleset ../../.spectral.yaml cleaned-openapi.yaml
```

#### Step 3: Import to APIM

```bash
cd ../../scripts

# Set environment variables
export RESOURCE_GROUP="rg-apim-migration"
export APIM_NAME="apim-migration"
export API_ID="migrated-api"
export OPENAPI_FILE="../tools/migration/cleaned-openapi.yaml"

# Import using provided script
./import-openapi.sh
```

#### Step 4: Configure Policies

Manually add policies to the imported API:

1. Navigate to Azure Portal → API Management → APIs
2. Select your imported API
3. Click "All operations" → Policies → Code editor
4. Add translated policies (see migration guide for examples)
5. Save and test

#### Step 5: Test

```bash
cd ../../tests

# Update environment variables
export APIM_URL="https://apim-migration.azure-api.net"
export SUBSCRIPTION_KEY="your-key"

# Run Postman tests
cd postman
newman run collection.json -e environment-migration.json

# Run load tests
cd ../k6
k6 run --vus 50 --duration 60s load-test.js
```

## Script Details

### translate-openapi.sh

**Features:**
- Validates input OpenAPI spec with Spectral
- Removes Google-specific extensions (`x-google-*`)
- Ensures OpenAPI 3.0 or 3.1 compliance
- Normalizes operation IDs for APIM compatibility
- Adds APIM-specific metadata if needed
- Outputs cleaned spec ready for import

**Limitations:**
- Does not translate embedded policy logic
- Cannot convert proprietary Google extensions automatically
- Manual review recommended for complex specs

**TODO for Implementation:**
- Add support for OpenAPI 2.0 (Swagger) conversion to 3.0
- Implement automatic operationId generation if missing
- Add validation for APIM-specific requirements

### translate-openapi.ps1

**Features:**
- Same as Bash version, PowerShell-native
- Better integration with Windows workflows
- Supports piping and PowerShell objects

**Limitations:**
- Same as Bash version

**TODO for Implementation:**
- Add PowerShell-native JSON/YAML parsing
- Implement progress bars for large specs
- Add `-WhatIf` parameter for preview mode

## Advanced Scenarios

### Bulk Migration

For migrating multiple APIs:

```bash
#!/bin/bash
# bulk-migrate.sh

for api_file in apis/*.yaml; do
  api_name=$(basename "$api_file" .yaml)
  echo "Migrating $api_name..."
  
  # Translate
  ./translate-openapi.sh "$api_file" "cleaned/$api_name.yaml"
  
  # Import
  ../../scripts/import-openapi.sh \
    -g "rg-apim-migration" \
    -n "apim-migration" \
    -i "$api_name" \
    -f "cleaned/$api_name.yaml"
done
```

### Policy Template Generator

**Future Enhancement:**
Create a tool that:
1. Reads Apigee policy XML
2. Identifies policy type
3. Generates equivalent APIM policy XML template
4. Flags areas requiring manual review

### Configuration Backup

Before migration, back up your Google API configs:

```bash
# Backup script
mkdir -p backups/$(date +%Y%m%d)

# Apigee
apigee-cli apis list -o your-org | while read api; do
  apigee-cli apis export -o your-org -n "$api" -f "backups/$(date +%Y%m%d)/${api}.zip"
done

# Google Cloud API Gateway
gcloud api-gateway apis list --format="value(name)" | while read api; do
  gcloud api-gateway api-configs list --api="$api" --format=json > "backups/$(date +%Y%m%d)/${api}-configs.json"
done
```

## Troubleshooting

### OpenAPI Translation Issues

**Issue**: Spectral validation fails with many errors
**Solution**: Review and fix critical errors first (schema validation, missing required fields). Some warnings can be ignored if they don't affect APIM import.

**Issue**: APIM import fails after translation
**Solution**: 
- Ensure operationIds are unique
- Check that all $ref references are resolved
- Verify server URLs are valid
- Remove any unsupported OpenAPI extensions

### Import Issues

**Issue**: API imports but policies don't work
**Solution**: Policies must be added manually after import. OpenAPI import only brings in API structure, not policy logic.

**Issue**: Operations missing after import
**Solution**: Check OpenAPI spec has complete path and operation definitions. APIM skips invalid operations.

## Additional Resources

- [Migration Guide](../../docs/migration/google-to-apim.md) - Complete migration process
- [Policy Examples](../../policies/) - APIM policy reference
- [Labs](../../labs/) - Hands-on tutorials
- [Scripts](../../scripts/) - Deployment and import automation

## Contributing

Found an issue or have an improvement?
1. Test your changes
2. Update this README
3. Submit a pull request

## Support

For questions or issues:
- Open a [GitHub issue](https://github.com/jonathandhaene/apim-educational/issues)
- Review [troubleshooting docs](../../docs/troubleshooting.md)
- Consult [migration guide](../../docs/migration/google-to-apim.md)

---

**Note**: These tools are provided as-is for educational and reference purposes. Always test thoroughly in non-production environments before using in production migrations.
