# AWS API Gateway to Azure API Management Migration Guide

This guide provides a comprehensive approach to migrating from Amazon API Gateway (REST and HTTP APIs) to Azure API Management (APIM).

## Table of Contents

- [Pre-Migration Assessment](#pre-migration-assessment)
- [Feature Mapping](#feature-mapping)
- [Migration Plan](#migration-plan)
- [Risks and Compatibility](#risks-and-compatibility)
- [Tooling and Automation](#tooling-and-automation)

## Pre-Migration Assessment

Before beginning your migration, conduct a thorough assessment of your existing API Gateway deployment using this checklist:

### API Resources and Configuration
- [ ] **API inventory**: Document all REST APIs, HTTP APIs, and WebSocket APIs
- [ ] **API definitions**: Export OpenAPI 3.0 specifications for each API
- [ ] **Resource paths**: Map all resource paths and HTTP methods
- [ ] **Request/response models**: Identify validation schemas and transformations
- [ ] **Integration types**: Document backend integrations (Lambda, HTTP, AWS Service, Mock, VPC Link)

### Stages and Deployments
- [ ] **Stage configuration**: List all stages (dev, test, prod) and their settings
- [ ] **Stage variables**: Document all stage variables and their usage
- [ ] **Deployment history**: Review deployment patterns and rollback procedures
- [ ] **Canary deployments**: Identify APIs using canary releases

### Domains and Certificates
- [ ] **Custom domains**: List all custom domain names configured
- [ ] **TLS certificates**: Document certificate sources (ACM, imported)
- [ ] **Base path mappings**: Map custom domains to API stages
- [ ] **Regional vs Edge-optimized**: Note endpoint types for each API

### Authentication and Authorization
- [ ] **API keys**: Count and document API key usage
- [ ] **IAM authorization**: Identify APIs using IAM-based auth
- [ ] **Lambda authorizers**: Document custom authorizers (request/token types)
- [ ] **Cognito authorizers**: List User Pools and scopes
- [ ] **Resource policies**: Review IAM resource policies

### Usage Plans and Throttling
- [ ] **Usage plans**: Document all usage plans and their quotas
- [ ] **API keys association**: Map API keys to usage plans
- [ ] **Throttle limits**: Record burst and rate limits per method/stage
- [ ] **Quota periods**: Note daily, weekly, or monthly quotas

### Rate Limiting and Caching
- [ ] **Method throttling**: Document per-method rate limits
- [ ] **Account-level limits**: Note AWS account-level throttling
- [ ] **Cache configuration**: Identify cached methods and TTL settings
- [ ] **Cache key parameters**: Document cache key customizations

### Logging and Monitoring
- [ ] **CloudWatch Logs**: Review access and execution logging settings
- [ ] **CloudWatch metrics**: List custom metrics and alarms
- [ ] **X-Ray tracing**: Identify APIs with tracing enabled
- [ ] **WAF integration**: Document WAF ACLs and rules

### Network Configuration
- [ ] **Endpoint types**: Classify as Edge-optimized, Regional, or Private
- [ ] **VPC Links**: Document VPC Link configurations for private resources
- [ ] **Private APIs**: List private APIs and VPC endpoints
- [ ] **IP whitelisting**: Review resource policy IP restrictions

### API Types
- [ ] **REST APIs**: Full-featured APIs with extensive configuration
- [ ] **HTTP APIs**: Lightweight, lower-cost APIs with limited features
- [ ] **WebSocket APIs**: Real-time bidirectional communication APIs
- [ ] **Feature differences**: Note which HTTP API limitations affect you

## Feature Mapping

This table maps AWS API Gateway features to their Azure APIM equivalents:

| AWS API Gateway Feature | Azure APIM Equivalent | Notes |
|------------------------|----------------------|-------|
| **API Definition** | API | APIM APIs support OpenAPI 2.0/3.0 import |
| **Resource + Method** | Operation | Each HTTP method becomes an operation |
| **Stage** | Revision (in-place) or Version (new path) | Revisions for non-breaking changes, Versions for breaking changes |
| **Stage Variables** | Named Values or Backend Variables | Named Values are global; use policy expressions for dynamic values |
| **Deployment** | Revision/Version Publishing | Explicit publish action required |
| **Custom Domain** | Custom Domain + Hostname | Configure via Portal or ARM templates |
| **Base Path Mapping** | API Path or Product | Use API path or group APIs into Products |
| **API Key** | Subscription Key | APIM uses subscription keys at Product or API scope |
| **Usage Plan** | Product + Rate Limit Policy | Products group APIs; policies enforce limits |
| **Throttle (rate limit)** | `rate-limit` or `quota` policy | Per-subscription or global limits |
| **Quota (usage limit)** | `quota` policy | Time-based call count limits |
| **Request Validator** | `validate-content` policy | Validates request body and parameters |
| **Model (schema)** | JSON schema in policy or operation | Define schemas in OpenAPI or policy |
| **IAM Authorization** | Azure AD / Managed Identity | Use `validate-jwt` policy for Azure AD tokens |
| **Lambda Authorizer** | Custom authorizer or Azure Function + `validate-jwt` | Call external service for validation |
| **Cognito Authorizer** | Azure AD B2C + `validate-jwt` | Validate JWT tokens from identity provider |
| **Resource Policy** | IP filter policy or Private Endpoint | Use `ip-filter` or restrict to VNet |
| **Request/Response Mapping** | `set-body`, `set-header`, transformation policies | Full XML-based policy language |
| **Integration Request/Response** | Backend configuration + policies | Configure backend and transform with policies |
| **VPC Link (private integration)** | Self-hosted Gateway or Private Endpoint | Deploy gateway in VNet or use private endpoints |
| **Mock Integration** | `mock-response` policy | Return static responses |
| **HTTP Integration** | Backend + `set-backend-service` | Direct HTTP backend calls |
| **AWS Service Integration** | Azure Function or Logic App + Backend | Integrate with Azure services |
| **Caching** | Built-in caching + `cache-lookup`/`cache-store` | Control caching per operation |
| **CloudWatch Logs** | Application Insights or Log Analytics | Diagnostic settings required |
| **X-Ray Tracing** | Application Insights distributed tracing | Automatic correlation with App Insights |
| **WAF** | Azure Front Door + WAF or Application Gateway + WAF | Front Door recommended for global APIs |
| **Edge-optimized endpoint** | Standard/Premium tier multi-region | Deploy to multiple Azure regions |
| **Regional endpoint** | Any APIM tier in single region | Deploy to closest Azure region |
| **Private endpoint** | Internal VNet mode or Private Link | Premium tier for VNet injection |
| **Binary media types** | Content-Type handling | APIM handles binary content automatically |
| **Canary deployment** | Revisions with traffic splitting | Use revision descriptions and testing |

## Migration Plan

Follow this phased approach to minimize risk and ensure a smooth migration:

### Phase 1: Inventory and Assessment (1-2 weeks)
1. **Document current state**
   - Export all OpenAPI specifications from API Gateway
   - Document stage variables, usage plans, and custom domains
   - List all Lambda authorizers and Cognito integrations
   - Inventory VPC Links and private API configurations

2. **Analyze dependencies**
   - Identify client applications and their API consumption patterns
   - Document SLAs and performance requirements
   - Review monitoring and alerting configurations

3. **Design target architecture**
   - Choose APIM tier based on requirements (see `docs/tiers-and-skus.md`)
   - Plan network topology (public, internal VNet, private endpoint)
   - Design product structure and subscription key strategy
   - Plan for custom domains and certificates

### Phase 2: OpenAPI Translation (1 week)
1. **Export OpenAPI from AWS**
   ```bash
   # Using AWS CLI
   aws apigateway get-export \
     --rest-api-id <api-id> \
     --stage-name <stage> \
     --export-type oas30 \
     --output-file api-export.json
   ```

2. **Clean AWS-specific extensions**
   - Remove `x-amazon-apigateway-*` extensions
   - Replace stage variables with Named Values or policy expressions
   - Convert AWS integrations to APIM backend configurations
   - Use `tools/migration/translate-openapi-aws.sh` script

3. **Add APIM-specific metadata**
   - Add `servers` section with APIM gateway URL
   - Define `securitySchemes` for subscription keys or OAuth
   - Add operation-level tags for organization

### Phase 3: APIM Setup and Configuration (2-3 weeks)
1. **Provision APIM instance**
   - Deploy using Bicep or Terraform templates from `infra/`
   - Configure networking (VNet, private endpoints if needed)
   - Set up Application Insights for diagnostics

2. **Configure domains and certificates**
   - Add custom domains (gateway, portal, management endpoints)
   - Upload or reference Key Vault certificates
   - Configure DNS CNAME records

3. **Import APIs**
   ```bash
   # Using import script
   ./scripts/import-openapi.sh
   
   # Or Azure CLI
   az apim api import \
     --resource-group <rg> \
     --service-name <apim-name> \
     --path <api-path> \
     --specification-format OpenApi \
     --specification-path translated-api.json
   ```

4. **Configure backends**
   - Define backend services (Function Apps, Logic Apps, HTTP endpoints)
   - Configure authentication (Managed Identity, certificates, keys)
   - Set connection properties (timeout, retry, circuit breaker)

5. **Apply policies**
   - **Authentication**: `validate-jwt`, `authentication-managed-identity`
   - **Rate limiting**: `rate-limit`, `quota`, `rate-limit-by-key`
   - **Transformation**: `set-header`, `set-body`, `set-query-parameter`
   - **Caching**: `cache-lookup-value`, `cache-store-value`
   - **CORS**: `cors` policy
   - Refer to `policies/` directory for examples

### Phase 4: Logging and Diagnostics (1 week)
1. **Configure Application Insights**
   - Link APIM to Application Insights instance
   - Enable sampling to control costs
   - Set up custom dimensions for filtering

2. **Set up Log Analytics**
   - Configure diagnostic settings
   - Route logs to Log Analytics workspace
   - Create custom queries and dashboards

3. **Configure alerts**
   - Set up metric alerts (availability, latency, errors)
   - Configure action groups for notifications
   - Test alert conditions

### Phase 5: Testing (2-3 weeks)
1. **Functional testing**
   - Test all API operations using Postman collections (`tests/postman/`)
   - Validate request/response transformations
   - Test error handling and validation

2. **Security testing**
   - Verify authentication and authorization
   - Test subscription key validation
   - Validate rate limiting and quotas

3. **Performance testing**
   - Run load tests using k6 (`tests/k6/`)
   - Compare latency with API Gateway baseline
   - Test under various load profiles

4. **Compatibility testing**
   - Test with actual client applications
   - Verify header handling and CORS
   - Test edge cases (large payloads, long-running requests)

### Phase 6: Cutover (Implementation varies)
Choose a cutover strategy based on your risk tolerance and requirements:

#### Blue/Green Deployment
1. Run APIM (green) in parallel with API Gateway (blue)
2. Route small percentage of traffic to APIM
3. Monitor metrics and errors
4. Gradually increase APIM traffic to 100%
5. Keep API Gateway running for rollback period
6. Decommission API Gateway after validation

**DNS-based approach:**
```bash
# Initial: All traffic to API Gateway
api.example.com -> API Gateway

# Cutover: Update DNS to APIM
api.example.com -> APIM Gateway

# DNS TTL: 300 seconds recommended
```

#### Weighted Traffic Splitting
Use Azure Front Door or a load balancer:
1. Configure Front Door with both API Gateway and APIM as backends
2. Set initial weight (e.g., 95% API Gateway, 5% APIM)
3. Monitor APIM performance and errors
4. Gradually shift weight (80/20, 50/50, 20/80)
5. Move to 100% APIM after validation
6. Remove API Gateway backend

**Front Door configuration:**
```json
{
  "backends": [
    {
      "address": "api-gateway.execute-api.us-east-1.amazonaws.com",
      "weight": 95
    },
    {
      "address": "apim-prod.azure-api.net",
      "weight": 5
    }
  ]
}
```

#### Phased Migration by API
Migrate one API or stage at a time:
1. Select low-risk API for pilot migration
2. Update clients to use APIM endpoint
3. Monitor for issues
4. Proceed with next API after validation
5. Migrate critical APIs last

**Client configuration:**
```javascript
// Old endpoint
const apiEndpoint = 'https://api.execute-api.us-east-1.amazonaws.com/prod';

// New endpoint
const apiEndpoint = 'https://apim-prod.azure-api.net/api/v1';
```

#### Rollback Plan
Always maintain a rollback plan:
1. Keep API Gateway running during migration
2. Document DNS or configuration changes needed to revert
3. Test rollback procedure before cutover
4. Set rollback decision criteria (error rate, latency SLO)
5. Have rollback on-call team identified

## Risks and Compatibility

Be aware of these differences between API Gateway and APIM that may impact your migration:

### HTTP Header Handling
- **Case sensitivity**: API Gateway normalizes header names to lowercase in Lambda proxy integrations; APIM preserves original casing
- **Impact**: Backend services expecting lowercase headers may need updates
- **Mitigation**: Use `set-header` policy to normalize casing if needed
  ```xml
  <set-header name="content-type" exists-action="override">
    <value>@(context.Request.Headers.GetValueOrDefault("Content-Type",""))</value>
  </set-header>
  ```

### Path and Query Parameter Handling
- **Encoding**: API Gateway double-decodes path parameters; APIM decodes once
- **Special characters**: Differences in handling `+`, `%20`, and other encoded characters
- **Impact**: APIs relying on specific encoding behavior may break
- **Mitigation**: Test thoroughly with special characters; use policy expressions to normalize

### Timeout Limits
- **API Gateway**: 30-second maximum integration timeout (29 seconds for HTTP APIs)
- **APIM**: 30-second default timeout (configurable up to 240 seconds in Developer tier and above)
- **Impact**: Long-running operations may behave differently
- **Mitigation**: Configure timeout in backend settings or use asynchronous patterns

### Payload Size Limits
- **API Gateway**: 10 MB request payload for REST APIs, 6 MB for HTTP APIs
- **APIM**: 4 MB for Consumption tier, varies by tier
- **Impact**: Large file uploads may fail in lower APIM tiers
- **Mitigation**: Use blob storage with SAS tokens for large files; upgrade APIM tier if needed

### CORS Differences
- **API Gateway**: CORS configured per method via OPTIONS mock integration
- **APIM**: CORS policy at API or global level
- **Impact**: Different header handling and preflight behavior
- **Mitigation**: Use APIM `cors` policy and test with browser clients
  ```xml
  <cors allow-credentials="true">
    <allowed-origins>
      <origin>https://example.com</origin>
    </allowed-origins>
    <allowed-methods>
      <method>GET</method>
      <method>POST</method>
    </allowed-methods>
  </cors>
  ```

### JWT Token Validation
- **API Gateway**: Cognito authorizer validates tokens from User Pools
- **APIM**: Generic JWT validation; supports any OIDC provider
- **Impact**: Token validation logic differs; may need policy adjustments
- **Mitigation**: Use `validate-jwt` policy with appropriate issuer and audience
  ```xml
  <validate-jwt header-name="Authorization" failed-validation-httpcode="401">
    <openid-config url="https://login.microsoftonline.com/{tenant}/.well-known/openid-configuration" />
    <audiences>
      <audience>api://{client-id}</audience>
    </audiences>
  </validate-jwt>
  ```

### Mutual TLS (mTLS)
- **API Gateway**: Native support for mTLS with custom domains
- **APIM**: mTLS supported for backend communication; client certificate validation via policy
- **Impact**: Client certificate authentication requires policy implementation
- **Mitigation**: Use `client-certificate` policy for validation

### Throttling Semantics
- **API Gateway**: Token bucket algorithm; burst capacity allows temporary spikes
- **API Gateway throttling**: Per-second rate with burst allowance
- **APIM rate-limit**: Sliding window or fixed window; no burst concept
- **APIM quota**: Absolute count over time period
- **Impact**: Burst traffic patterns may be handled differently
- **Mitigation**: Adjust rate limits based on testing; consider burst patterns

### Caching Behavior
- **API Gateway**: Cache key includes query strings, headers by configuration
- **APIM**: Cache key based on URL, query parameters, headers (configurable)
- **TTL**: API Gateway max 3600 seconds; APIM configurable per tier
- **Impact**: Cache hit rates may differ
- **Mitigation**: Configure cache-lookup policy with appropriate vary-by settings
  ```xml
  <cache-lookup vary-by-developer="false" vary-by-developer-groups="false">
    <vary-by-query-parameter>page</vary-by-query-parameter>
    <vary-by-header>Accept-Language</vary-by-header>
  </cache-lookup>
  ```

### Stage Variables vs Named Values
- **API Gateway**: Stage variables scoped to deployment stage
- **APIM**: Named Values global to APIM instance; no stage concept
- **Impact**: Environment-specific configuration requires different approach
- **Mitigation**: Use Named Values for global config; policy expressions for dynamic values
  ```xml
  <!-- Named Value -->
  {{backend-url}}
  
  <!-- Policy expression for dynamic routing -->
  @{
    return context.Request.Headers.GetValueOrDefault("X-Environment") == "dev"
      ? "https://dev-backend.example.com"
      : "https://prod-backend.example.com";
  }
  ```

### Latency and Performance
- **API Gateway Edge-optimized**: CloudFront CDN reduces latency for geographically distributed users
- **APIM**: No built-in CDN; use Azure Front Door for global distribution
- **Additional hops**: APIM adds processing overhead (typically 5-20ms)
- **Impact**: Latency-sensitive applications may see degradation
- **Mitigation**: 
  - Deploy APIM in multiple regions for geo-distributed users
  - Use Premium tier for better performance
  - Integrate with Azure Front Door for caching and global routing
  - Enable APIM caching for cacheable responses

### WebSocket APIs
- **API Gateway**: Native WebSocket API support with $connect, $disconnect routes
- **APIM**: Limited WebSocket support; primarily for SignalR
- **Impact**: WebSocket APIs require redesign or alternative approach
- **Mitigation**: Consider Azure SignalR Service or Azure Web PubSub for real-time scenarios

### REST vs HTTP API Differences
If migrating from HTTP APIs (not REST APIs):
- **Authorizers**: HTTP APIs have simplified JWT authorizers; ensure APIM `validate-jwt` covers requirements
- **Parameter mapping**: HTTP APIs have simpler parameter handling; test edge cases
- **CORS**: HTTP APIs have simplified CORS; validate APIM policy achieves same behavior

## Tooling and Automation

Leverage these tools for migration and validation:

### Migration Tools
- **OpenAPI translation**: `tools/migration/translate-openapi-aws.sh` - Clean AWS extensions
- **PowerShell version**: `tools/migration/translate-openapi-aws.ps1` - Windows support
- **Import script**: `scripts/import-openapi.sh` - Automated API import to APIM

### Validation and Testing
- **Spectral linting**: Validate OpenAPI specs before import
  ```bash
  npm install -g @stoplight/spectral-cli
  spectral lint translated-api.json --ruleset .spectral.yaml
  ```
- **Postman collections**: Test APIs functionally (`tests/postman/`)
  ```bash
  newman run tests/postman/api-tests.json -e tests/postman/apim-env.json
  ```
- **k6 load testing**: Performance and load testing (`tests/k6/`)
  ```bash
  k6 run tests/k6/load-test.js --vus 100 --duration 5m
  ```

### Self-Hosted Gateway
For hybrid scenarios or VPC connectivity:
- **Docker Compose**: `gateway/docker-compose.yml` - Local testing
- **Kubernetes**: `gateway/k8s/` - Production deployment in AKS or on-premises

### Azure CLI Examples
```bash
# List all APIs in APIM
az apim api list --resource-group <rg> --service-name <apim-name>

# Show API details
az apim api show --resource-group <rg> --service-name <apim-name> --api-id <api-id>

# Export API as OpenAPI
az apim api export --resource-group <rg> --service-name <apim-name> --api-id <api-id> --export-format openapi-json --output-file exported-api.json

# Update API policy
az apim api policy create --resource-group <rg> --service-name <apim-name> --api-id <api-id> --xml-policy-file policy.xml

# Test API
curl -H "Ocp-Apim-Subscription-Key: YOUR_KEY" https://<apim-name>.azure-api.net/<api-path>/resource
```

### Additional Resources
- [Azure APIM Documentation](https://learn.microsoft.com/azure/api-management/)
- [OpenAPI Specification](https://swagger.io/specification/)
- [API Management Policy Reference](https://learn.microsoft.com/azure/api-management/api-management-policies)
- [Migration from API Gateway - Official Guide](https://learn.microsoft.com/azure/api-management/migrate-api-gateway)
- Repository resources:
  - Infrastructure templates: `infra/bicep/` and `infra/terraform/`
  - Policy examples: `policies/` and `policies/fragments/`
  - Sample tests: `tests/postman/`, `tests/k6/`, `tests/rest-client/`

## Next Steps

1. **Review this guide** with your team and stakeholders
2. **Complete the assessment checklist** to understand your current state
3. **Identify pilot API** for initial migration
4. **Set up development APIM instance** using `infra/` templates
5. **Test migration workflow** with pilot API
6. **Document learnings** and adjust plan
7. **Execute phased migration** according to your chosen strategy
8. **Celebrate success!** 🎉

For questions or contributions, see [CONTRIBUTING.md](../../CONTRIBUTING.md).
