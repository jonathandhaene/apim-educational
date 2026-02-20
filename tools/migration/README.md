# Migration Tools for API Gateway to Azure APIM

This directory contains scripts and utilities to assist with migrating from Google's API services (Apigee, Cloud API Gateway) or AWS API Gateway to Azure API Management.

## Overview

Migration from API gateway services to Azure APIM involves:
1. **Assessment**: Inventory APIs, policies, configurations
2. **Translation**: Convert OpenAPI specs and policies
3. **Import**: Load APIs and configurations into APIM
4. **Validation**: Test and verify functionality
5. **Cutover**: Switch traffic to APIM

## Tools Provided

### 1. openapi_utils.py — Core Processing Library

**Purpose**: Python library that performs the heavy lifting for all translation scripts.

**Features**:
- **Swagger 2.0 → OpenAPI 3.0 conversion** — converts `swagger: "2.0"` specs to `openapi: "3.0.0"`, including `servers[]` from `host`/`basePath`/`schemes`, `components/securitySchemes` from `securityDefinitions`, `components/schemas` from `definitions`, `requestBody` from body/formData parameters, and `$ref` path rewriting.
- **Automatic `operationId` generation** — generates descriptive camelCase IDs (`getUsers`, `postUsersByUserId`) for any operation that lacks one; disambiguates duplicates with a numeric suffix.
- **APIM requirement validation** — checks for mandatory `info.title` and `info.version`, at least one server URL, supported security scheme types, and unique `operationId` values.
- **Vendor extension removal** — strips `x-amazon-*` (AWS) or `x-google-*` (Google) extensions from all levels of the spec.

**Usage**:
```bash
# AWS API Gateway spec
python3 openapi_utils.py aws-export.yaml apim-api.yaml --source aws

# Google API Gateway / Apigee spec
python3 openapi_utils.py google-export.yaml apim-api.yaml --source google

# Validate only (no output file written)
python3 openapi_utils.py spec.yaml /dev/null --validate-only

# Skip Swagger→OAS3 conversion or operationId generation
python3 openapi_utils.py spec.yaml out.yaml --no-convert
python3 openapi_utils.py spec.yaml out.yaml --no-operationid
```

**Prerequisites**:
```bash
pip install pyyaml
```

**Tests**:
```bash
# Run unit tests (45 tests covering all major features)
python3 -m pytest tests/test_openapi_utils.py -v
```

---

### 2. OpenAPI Translation Scripts

**Purpose**: Shell and PowerShell wrappers that orchestrate Spectral linting and call `openapi_utils.py`.

#### translate-openapi.sh / translate-openapi.ps1 (Google API Gateway / Apigee)

```bash
# Bash (Linux/macOS)
./translate-openapi.sh google-api.yaml apim-api.yaml

# PowerShell (Windows)
.\translate-openapi.ps1 -InputFile google-api.yaml -OutputFile apim-api.yaml
```

What it does:
1. Validates input spec with Spectral (if installed)
2. Removes `x-google-*` extensions
3. Converts Swagger 2.0 → OpenAPI 3.0 (if applicable)
4. Generates missing `operationId` values
5. Validates APIM requirements
6. Validates output spec with Spectral

#### translate-openapi-aws.sh / translate-openapi-aws.ps1 (AWS API Gateway)

```bash
# Export from AWS first
aws apigateway get-export \
  --rest-api-id <api-id> --stage-name prod \
  --export-type oas30 --accepts application/yaml \
  > aws-api-export.yaml

# Bash (Linux/macOS)
./translate-openapi-aws.sh aws-api-export.yaml apim-api.yaml

# PowerShell (Windows)
.\translate-openapi-aws.ps1 -InputFile aws-api-export.yaml -OutputFile apim-api.yaml
```

What it does — same pipeline as the Google version, but targets `x-amazon-*` extensions.

---

### 3. Policy Translation Guidance

**Manual Translation Required**: Policy translation cannot be fully automated due to semantic differences between platforms.

- **Google → APIM**: Use the [Google to APIM Migration Guide](../../docs/migration/google-to-apim.md)
- **AWS → APIM**: Use the [AWS to APIM Migration Guide](../../docs/migration/aws-to-apim.md)

**Process**:
1. Export policies from source platform
2. Identify equivalent APIM policies (see mapping tables in guides)
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

### openapi_utils.py

**Features:**
- Converts Swagger 2.0 → OpenAPI 3.0 (servers, securitySchemes, requestBody, $ref rewrites)
- Generates camelCase `operationId` values for operations that lack them
- Validates mandatory APIM fields (title, version, server URL, security schemes, unique operationIds)
- Removes `x-amazon-*` or `x-google-*` vendor extensions

**Limitations:**
- Does not translate policy logic (Lambda authorizers, Apigee policies, etc.)
- Swagger 2.0 conversion covers common patterns; highly custom specs may need manual review

### translate-openapi.sh / translate-openapi.ps1

**Features:**
- Validates input OpenAPI spec with Spectral
- Removes Google-specific extensions (`x-google-*`) via `openapi_utils.py`
- Converts Swagger 2.0 → OpenAPI 3.0 via `openapi_utils.py`
- Generates missing `operationId` values
- Validates APIM-specific requirements
- Outputs cleaned spec ready for import

**Limitations:**
- Does not translate embedded policy logic
- Manual review recommended for complex specs

### translate-openapi-aws.sh / translate-openapi-aws.ps1

**Features:**
- Same pipeline as the Google scripts, but targets `x-amazon-*` extensions
- Supports AWS REST API and HTTP API exports

**Limitations:**
- Same as Google translation scripts

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

- [Google to APIM Migration Guide](../../docs/migration/google-to-apim.md) - Complete Google migration process
- [AWS to APIM Migration Guide](../../docs/migration/aws-to-apim.md) - Complete AWS migration process
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
