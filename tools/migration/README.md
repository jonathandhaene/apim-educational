# API Migration Tools

This directory contains tools to help migrate APIs from various cloud providers to Azure API Management (APIM).

## Overview

These tools assist with OpenAPI specification translation, removing cloud-specific extensions, and preparing specs for APIM import.

## Supported Migration Paths

### AWS API Gateway → Azure APIM

Migrate from Amazon API Gateway (REST or HTTP APIs) to Azure APIM.

**Tools:**
- `translate-openapi-aws.sh` - Bash script for Linux/macOS
- `translate-openapi-aws.ps1` - PowerShell script for Windows/cross-platform

**Key transformations:**
- Remove AWS-specific extensions (`x-amazon-apigateway-*`)
- Convert stage variables to APIM Named Values placeholders
- Remove AWS integration configurations
- Prepare OpenAPI spec for APIM import

**Usage (Bash):**
```bash
./translate-openapi-aws.sh input-api.json output-api.json
```

**Usage (PowerShell):**
```powershell
.\translate-openapi-aws.ps1 -InputFile input-api.json -OutputFile output-api.json
```

**Workflow:**
1. **Export OpenAPI from AWS API Gateway:**
   ```bash
   # Export using AWS CLI
   aws apigateway get-export \
     --rest-api-id abc123xyz \
     --stage-name prod \
     --export-type oas30 \
     --output-file aws-api-export.json
   ```

2. **Translate OpenAPI spec:**
   ```bash
   # Run translation script
   ./tools/migration/translate-openapi-aws.sh \
     aws-api-export.json \
     apim-ready-api.json
   ```

3. **Review and customize:**
   - Check for remaining AWS-specific references
   - Add APIM-specific metadata (servers, security schemes)
   - Update backend URLs if needed

4. **Lint the translated spec:**
   ```bash
   # Use Spectral to validate
   spectral lint apim-ready-api.json --ruleset .spectral.yaml
   ```

5. **Import to APIM:**
   ```bash
   # Use the import script
   OPENAPI_FILE=apim-ready-api.json \
   API_ID=migrated-api \
   API_PATH=api/v1 \
   ./scripts/import-openapi.sh
   ```

### Google Cloud API Gateway → Azure APIM

Coming soon! Tools for migrating from Google Cloud API Gateway will follow a similar pattern.

## Common Post-Migration Tasks

After translating and importing your OpenAPI spec, you'll typically need to:

1. **Configure backends:**
   - Update backend service URLs
   - Configure authentication (Managed Identity, certificates, API keys)
   - Set timeouts and retry policies

2. **Apply policies:**
   - Add authentication (`validate-jwt`, subscription keys)
   - Configure rate limiting (`rate-limit`, `quota`)
   - Add transformation policies (`set-header`, `set-body`)
   - Enable caching where appropriate

3. **Test thoroughly:**
   - Run functional tests (`tests/postman/`)
   - Execute load tests (`tests/k6/`)
   - Validate with actual client applications

4. **Configure monitoring:**
   - Set up Application Insights
   - Configure diagnostic logs
   - Create metric alerts

## Script Details

### translate-openapi-aws.sh

Bash script that uses `jq` to:
- Parse OpenAPI JSON specification
- Remove all `x-amazon-apigateway-*` extensions
- Strip out integration configurations
- Clean up AWS-specific references
- Output APIM-ready OpenAPI spec

**Requirements:**
- `jq` (JSON processor): `sudo apt install jq` or `brew install jq`
- Bash 4.0+

**Output:**
- Clean OpenAPI 3.0 specification
- Ready for Spectral validation
- Compatible with APIM import

### translate-openapi-aws.ps1

PowerShell script that:
- Loads OpenAPI JSON specification
- Removes AWS-specific extensions using PowerShell JSON manipulation
- Cleans integration references
- Outputs APIM-ready OpenAPI spec

**Requirements:**
- PowerShell 7+ (recommended) or Windows PowerShell 5.1
- No external dependencies

**Output:**
- Clean OpenAPI 3.0 specification
- Cross-platform compatible
- Ready for APIM import

## Best Practices

1. **Always backup original specs** before translation
2. **Review diffs** after translation to understand changes
3. **Validate with Spectral** before importing to APIM
4. **Test incrementally** - start with one API before migrating all
5. **Document customizations** made to translated specs
6. **Version control** your OpenAPI specifications

## Troubleshooting

### Issue: jq command not found
**Solution:** Install jq using your package manager:
```bash
# Ubuntu/Debian
sudo apt-get install jq

# macOS
brew install jq

# Windows (via Chocolatey)
choco install jq
```

### Issue: PowerShell script execution disabled
**Solution:** Enable script execution:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Issue: Translation removes needed extensions
**Solution:** These scripts are starting points. Customize them to preserve extensions you need:
```bash
# Edit the script to preserve specific x-* extensions
# Look for the deletion logic and add exceptions
```

### Issue: Translated spec fails Spectral validation
**Solution:** 
1. Review Spectral errors in detail
2. Add missing required fields (summary, operationId, tags)
3. Fix schema validation issues
4. Run validation again

## Additional Resources

- [AWS to APIM Migration Guide](../../docs/migration/aws-to-apim.md)
- [OpenAPI Specification](https://swagger.io/specification/)
- [Spectral Linting Rules](../../.spectral.yaml)
- [APIM Import Scripts](../../scripts/)
- [Azure APIM Policy Reference](https://learn.microsoft.com/azure/api-management/api-management-policies)

## Contributing

Contributions are welcome! If you've developed migration tools for other platforms or improvements to existing tools, please submit a pull request. See [CONTRIBUTING.md](../../CONTRIBUTING.md) for guidelines.

## License

These tools are provided as-is under the repository license. See [LICENSE](../../LICENSE) for details.
