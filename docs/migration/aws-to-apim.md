# Migrating from AWS API Gateway to Azure API Management

This guide provides a comprehensive roadmap for migrating from AWS API Gateway (REST API and HTTP API) to Azure API Management (APIM).

> **⚠️ Educational Disclaimer**: This repository is provided for educational and learning purposes only. All content, including pricing estimates, tier recommendations, and infrastructure templates, should be validated and adapted for your specific production requirements. Azure API Management features, pricing, and best practices evolve frequently—always consult the <a href="https://learn.microsoft.com/azure/api-management/">official Azure documentation</a> and <a href="https://azure.microsoft.com/pricing/calculator/">Azure Pricing Calculator</a> for the most current information before making production decisions.

## Table of Contents

1. [Assessment Phase](#assessment-phase)
2. [Mapping Guide](#mapping-guide)
3. [Migration Plan](#migration-plan)
4. [Tooling and Automation](#tooling-and-automation)
5. [Risk and Compatibility Notes](#risk-and-compatibility-notes)
6. [Testing and Validation](#testing-and-validation)
7. [Cutover and Rollback](#cutover-and-rollback)

## Assessment Phase

### Inventory Your Current Environment

#### 1. API Inventory

**AWS API Gateway:**
```bash
# List all REST APIs
aws apigateway get-rest-apis --region us-east-1 --output json

# List all HTTP APIs
aws apigatewayv2 get-apis --region us-east-1 --output json

# Export REST API to OpenAPI
aws apigateway get-export \
  --rest-api-id your-api-id \
  --stage-name prod \
  --export-type oas30 \
  --accepts application/yaml \
  > api-export.yaml

# Export HTTP API to OpenAPI
aws apigatewayv2 export-api \
  --api-id your-api-id \
  --output-type YAML \
  --specification OAS30 \
  --stage-name prod \
  > http-api-export.yaml
```

Create an inventory spreadsheet with:
- API Name and ID
- API Type (REST/HTTP)
- Number of resources/routes and methods
- Current traffic volume (requests/day)
- Authentication method (API key, Lambda authorizer, Cognito, IAM)
- Throttling limits (burst and rate)
- Dependencies on other AWS services

#### 2. Stages and Deployments

**Document:**
- Number of stages (dev, test, prod)
- Stage variables and their usage
- Deployment history and rollback strategy
- Stage-specific configurations (caching, throttling, logging)
- Canary deployments and traffic distribution

#### 3. Integrations

**Identify integration types:**
- Lambda functions (proxy and non-proxy)
- HTTP/HTTPS backends
- AWS service integrations (DynamoDB, S3, SNS, SQS, etc.)
- VPC Links to private resources
- Mock integrations

**Document:**
- Integration request/response mappings
- Velocity templates (VTL) in use
- Request/response transformations
- Integration timeouts

#### 4. Authentication and Authorization

**Document current auth patterns:**
- API keys (header, query parameter)
- Lambda authorizers (token-based, request-based)
- Amazon Cognito User Pools
- IAM authentication and authorization
- mTLS (mutual TLS) configurations
- Resource policies and permissions

#### 5. Throttling and Quotas

**Identify:**
- Account-level rate limits
- API-level throttling (burst and rate)
- Stage-level throttling
- Usage plans and associated API keys
- Per-client quotas (daily, weekly, monthly)

#### 6. Caching

**Current setup:**
- Stage cache enabled/disabled
- Cache capacity (0.5GB to 237GB)
- Cache TTL settings
- Per-method cache overrides
- Cache key parameters
- Encryption at rest

#### 7. VPC Links and Private Integrations

**Inventory:**
- VPC Link configurations
- Network Load Balancers (NLB) or Application Load Balancers (ALB)
- Private backend services
- Security groups and network ACLs
- VPC endpoints (if used)

#### 8. Custom Domains and Certificates

**Inventory:**
- Custom domain names
- Regional vs edge-optimized endpoints
- ACM certificates (expiration dates, SANs)
- Base path mappings
- DNS configurations (Route 53 or external)
- Certificate renewal processes

#### 9. Request/Response Transformations

**Document:**
- Request validators (body, parameters, headers)
- Model schemas (JSON Schema)
- Velocity templates for mapping
- Gateway responses (error responses, CORS, etc.)
- Binary media types

#### 10. Logging and Monitoring

**Current setup:**
- CloudWatch Logs (execution logs, access logs)
- CloudWatch Metrics and alarms
- X-Ray tracing
- Log format and retention
- Custom metrics and dashboards
- SNS notifications for alarms

#### 11. WAF Integration

**If using AWS WAF:**
- WAF ACLs attached to API stages
- Rules and rule groups
- IP sets and rate-based rules
- Geographic restrictions
- Managed rule sets

## Mapping Guide

### Core Concepts Mapping

| AWS API Gateway | Azure APIM | Notes |
|-----------------|------------|-------|
| REST API / HTTP API | API | Container for operations |
| Resource | API Operation | Individual endpoint/method |
| Stage | Named Values / Revisions | Environment configuration |
| Method | Operation | HTTP method on a path |
| Integration | Backend | Backend service connection |
| API Key | Subscription Key | Access credential |
| Usage Plan | Product + Subscription | API bundling with quotas |
| Lambda Authorizer | validate-jwt / Policy | Custom authorization logic |
| Stage Variables | Named Values | Configuration variables |
| Request Validator | validate-content | Input validation |
| Gateway Response | return-response | Custom error responses |
| VPC Link | Backend / VNet Integration | Private backend access |
| Resource Policy | ip-filter / Policy | Access control |
| CloudWatch Logs | Application Insights / Log Analytics | Monitoring and logging |
| X-Ray | Application Insights | Distributed tracing |
| Deployment | API Revision | API versioning/deployment |
| Canary | Revision with traffic split | Gradual rollout |

### Policy Mapping

#### AWS API Gateway Features → Azure APIM Policies

| AWS Feature | APIM Policy | Implementation |
|-------------|-------------|----------------|
| API Key | subscription-required | Built-in subscription validation |
| Lambda Authorizer (JWT) | validate-jwt | JWT validation with OIDC providers |
| Cognito User Pools | validate-jwt | JWT validation with Cognito issuer |
| IAM Authorization | N/A | Use Azure AD / Managed Identity |
| Throttling (Rate Limit) | rate-limit / rate-limit-by-key | Per-subscription rate limiting |
| Throttling (Burst) | rate-limit-by-key | Short-term burst control |
| Usage Plan Quota | quota / quota-by-key | Time-based request limits |
| Stage Cache | cache-lookup / cache-store | Response caching |
| Request Validation | validate-content / validate-parameters | Schema validation |
| Request Transformation | set-body / set-header | Request modification |
| Response Transformation | set-body / set-header | Response modification |
| VTL Mapping Templates | C# expressions / Liquid templates | Data transformation |
| CORS | cors | Cross-origin requests |
| Binary Media Types | set-header | Content-Type handling |
| Gateway Responses | on-error / return-response | Error handling |
| Resource Policy | ip-filter | IP allowlisting/denylisting |
| mTLS | validate-client-certificate | Client certificate validation |

### Authentication Mapping

#### API Key Authentication

**AWS API Gateway:**
```yaml
# Usage plan with API key
x-amazon-apigateway-api-key-source: HEADER
security:
  - api_key: []
```

**APIM:**
```xml
<inbound>
    <base />
    <!-- Subscription key validation is automatic -->
    <!-- For custom header location: -->
    <check-header name="X-API-Key" failed-check-httpcode="401" failed-check-error-message="API key missing or invalid" ignore-case="true" />
</inbound>
```

#### Lambda Authorizer with JWT

**AWS API Gateway:**
```yaml
securitySchemes:
  BearerAuth:
    type: apiKey
    name: Authorization
    in: header
    x-amazon-apigateway-authorizer:
      type: jwt
      jwtConfiguration:
        audience:
          - "api-audience"
        issuer: "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_xxxxx"
```

**APIM:**
```xml
<inbound>
    <base />
    <validate-jwt header-name="Authorization" failed-validation-httpcode="401">
        <openid-config url="https://cognito-idp.us-east-1.amazonaws.com/us-east-1_xxxxx/.well-known/openid-configuration" />
        <audiences>
            <audience>api-audience</audience>
        </audiences>
        <required-claims>
            <claim name="scope" match="all">
                <value>read</value>
            </claim>
        </required-claims>
    </validate-jwt>
</inbound>
```

#### Throttling Configuration

**AWS API Gateway (Usage Plan):**
```json
{
  "throttle": {
    "burstLimit": 1000,
    "rateLimit": 500
  },
  "quota": {
    "limit": 10000,
    "period": "DAY"
  }
}
```

**APIM:**
```xml
<inbound>
    <base />
    <!-- Rate limiting - 500 requests per second (renewal-period in seconds) -->
    <rate-limit-by-key calls="30000" 
                       renewal-period="60" 
                       counter-key="@(context.Subscription.Id)" />
    
    <!-- Burst limiting (additional short-term limit) -->
    <rate-limit-by-key calls="1000" 
                       renewal-period="10" 
                       counter-key="@(context.Subscription.Id)" />
    
    <!-- Quota (daily limit) -->
    <quota-by-key calls="10000" 
                  renewal-period="86400" 
                  counter-key="@(context.Subscription.Id)" />
</inbound>
```

#### Request/Response Transformation

**AWS API Gateway (VTL):**
```velocity
#set($inputRoot = $input.path('$'))
{
  "transformed": {
    "userId": "$inputRoot.user.id",
    "timestamp": "$context.requestTime"
  }
}
```

**APIM (C# expression):**
```xml
<inbound>
    <base />
    <set-body>@{
        var body = context.Request.Body.As<JObject>(preserveContent: true);
        return new JObject(
            new JProperty("transformed", new JObject(
                new JProperty("userId", body["user"]["id"]),
                new JProperty("timestamp", DateTime.UtcNow.ToString("o"))
            ))
        ).ToString();
    }</set-body>
</inbound>
```

**APIM (Liquid template):**
```xml
<inbound>
    <base />
    <set-body template="liquid">
    {
        "transformed": {
            "userId": "{{body.user.id}}",
            "timestamp": "{{context.Timestamp}}"
        }
    }
    </set-body>
</inbound>
```

## Migration Plan

### Phase 1: Planning and Design (Week 1-2)

#### Activities:
1. ✅ Complete assessment (inventory all APIs, stages, integrations)
2. ✅ Design APIM architecture (tier, networking, regions)
   - Choose appropriate tier (Developer for testing; Basic v2, Standard v2, or classic tiers for production)
   - Note: v2 tiers offer consumption-based pricing and auto-scaling
   - Plan network architecture (public, VNet integration, private endpoints)
   - Consider multi-region requirements (Premium tier only)
3. ✅ Map policies, authorizers, and authentication patterns
4. ✅ Plan VPC Link to VNet integration migration
5. ✅ Design DNS and domain migration strategy
6. ✅ Map Lambda authorizers to APIM policies
7. ✅ Define rollback procedures
8. ✅ Set up Azure environment and APIM instance

#### Deliverables:
- Migration architecture document
- Policy and authorizer mapping spreadsheet
- Integration mapping (Lambda, HTTP, AWS services)
- Risk assessment and mitigation plan
- Test plan and success criteria
- Rollback procedures

### Phase 2: Infrastructure Setup (Week 2-3)

#### Activities:
1. Deploy APIM instance
   - **Testing/POC**: Developer tier (~$50/month) or Consumption tier (pay-per-use)
   - **Production**: Basic v2 or Standard v2 (consumption-based, auto-scaling) or classic tiers (fixed pricing)
   - **See**: [Tier comparison guide](../tiers-and-skus.md) for detailed feature and pricing comparison
2. Configure networking (VNet, private endpoints if needed)
   - Note: VNet injection requires Developer, Standard, Premium (classic) or Standard v2 tiers
3. Set up Application Insights and Log Analytics
4. Configure Azure Key Vault for secrets
5. Set up CI/CD pipeline for APIM deployments
6. Deploy IaC templates (Bicep/Terraform)
7. Configure VNet integration for private backends (if replacing VPC Links)

#### Example Bicep Deployment:

```bash
cd infra/bicep

# Deploy APIM with required features
az deployment group create \
  --resource-group rg-apim-migration \
  --template-file main.bicep \
  --parameters @params/migration.bicepparam
```

#### Example Terraform:

```bash
cd infra/terraform

terraform init
terraform plan -var-file="migration.tfvars"
terraform apply -var-file="migration.tfvars"
```

### Phase 3: API Migration (Week 3-6)

#### Step-by-Step Process:

**1. Export OpenAPI Specifications from AWS**

From AWS API Gateway:
```bash
# Export REST API (OpenAPI 3.0)
aws apigateway get-export \
  --rest-api-id abc123 \
  --stage-name prod \
  --export-type oas30 \
  --accepts application/yaml \
  > rest-api-export.yaml

# Export HTTP API
aws apigatewayv2 export-api \
  --api-id def456 \
  --output-type YAML \
  --specification OAS30 \
  --stage-name prod \
  > http-api-export.yaml

# Export for all APIs in region
aws apigateway get-rest-apis --query 'items[*].[id,name]' --output text | \
while read id name; do
  aws apigateway get-export \
    --rest-api-id "$id" \
    --stage-name prod \
    --export-type oas30 \
    --accepts application/yaml \
    > "${name}-export.yaml"
done
```

**2. Lint and Clean OpenAPI Specs**

Use the provided tooling:
```bash
cd tools/migration

# Lint with Spectral
spectral lint --ruleset ../../.spectral.yaml aws-api-export.yaml

# Translate and clean AWS-specific extensions
./translate-openapi-aws.sh aws-api-export.yaml cleaned-openapi.yaml

# Verify the output
spectral lint --ruleset ../../.spectral.yaml cleaned-openapi.yaml
```

**3. Import APIs to APIM**

```bash
# Set variables
RESOURCE_GROUP="rg-apim-migration"
APIM_NAME="apim-migration"
API_ID="migrated-api"

# Import OpenAPI spec using repository script
cd ../../scripts
export RESOURCE_GROUP="${RESOURCE_GROUP}"
export APIM_NAME="${APIM_NAME}"
export API_ID="${API_ID}"
export OPENAPI_FILE="../tools/migration/cleaned-openapi.yaml"
./import-openapi.sh

# Or use Azure CLI directly
az apim api import \
  --resource-group ${RESOURCE_GROUP} \
  --service-name ${APIM_NAME} \
  --api-id ${API_ID} \
  --path /api/v1 \
  --specification-format OpenApiJson \
  --specification-path ../tools/migration/cleaned-openapi.yaml \
  --display-name "Migrated API from AWS"
```

**4. Translate Lambda Authorizers and Policies**

Manual policy translation is required. Use the mapping guide above.

**Example: Lambda JWT Authorizer to APIM**

AWS Lambda Authorizer Configuration:
```yaml
x-amazon-apigateway-authorizer:
  type: jwt
  jwtConfiguration:
    audience:
      - "aud-value"
    issuer: "https://cognito-idp.region.amazonaws.com/pool-id"
```

Equivalent APIM policy:
```xml
<inbound>
    <base />
    <validate-jwt header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Unauthorized">
        <openid-config url="https://cognito-idp.us-east-1.amazonaws.com/us-east-1_xxxxx/.well-known/openid-configuration" />
        <audiences>
            <audience>aud-value</audience>
        </audiences>
        <issuers>
            <issuer>https://cognito-idp.region.amazonaws.com/pool-id</issuer>
        </issuers>
    </validate-jwt>
</inbound>
```

**Example: Request Transformation**

AWS VTL Template:
```velocity
{
  "requestId": "$context.requestId",
  "body": $input.json('$')
}
```

APIM Policy:
```xml
<inbound>
    <base />
    <set-body>@{
        var body = context.Request.Body.As<JObject>(preserveContent: true);
        return new JObject(
            new JProperty("requestId", context.RequestId),
            new JProperty("body", body)
        ).ToString();
    }</set-body>
</inbound>
```

**5. Configure Backends**

For HTTP/HTTPS backends:
```bash
# Create backend
az apim backend create \
  --resource-group ${RESOURCE_GROUP} \
  --service-name ${APIM_NAME} \
  --backend-id aws-backend \
  --url "https://api.example.com" \
  --protocol http \
  --description "AWS backend service"
```

For private backends (replacing VPC Links):
```bash
# Configure VNet integration
# Backend must be accessible from APIM's VNet

# Create backend with private URL
az apim backend create \
  --resource-group ${RESOURCE_GROUP} \
  --service-name ${APIM_NAME} \
  --backend-id private-backend \
  --url "http://internal-service.local" \
  --protocol http \
  --description "Private backend (was VPC Link)"
```

Policy configuration:
```xml
<inbound>
    <base />
    <set-backend-service backend-id="aws-backend" />
</inbound>
```

**6. Migrate Custom Domains and Certificates**

```bash
# Upload certificate to Key Vault
KV_NAME="kv-apim-migration"

# Import certificate (convert from ACM if needed)
# Export from ACM and convert to PFX format first
az keyvault certificate import \
  --vault-name ${KV_NAME} \
  --name api-custom-domain \
  --file certificate.pfx \
  --password "cert-password"

# Configure custom domain in APIM
# Via Azure Portal: APIM → Custom domains → Add
# Or use Azure CLI
az apim api update \
  --resource-group ${RESOURCE_GROUP} \
  --service-name ${APIM_NAME} \
  --api-id ${API_ID} \
  --display-name "API with custom domain"

# Configure hostname in APIM settings
```

**7. Configure WAF (if migrating from AWS WAF)**

```bash
# Deploy Azure Application Gateway with WAF in front of APIM
# Or use Azure Front Door with WAF

# Example: Application Gateway WAF rules
# Configure similar rules to AWS WAF ACLs:
# - IP allowlist/blocklist
# - Rate limiting
# - Geographic restrictions
# - OWASP Core Rule Set

# Reference Azure WAF policy in Application Gateway
```

**8. Set Up Logging**

```bash
# Application Insights is typically configured during APIM setup

# Configure additional diagnostic settings
az monitor diagnostic-settings create \
  --name apim-logs \
  --resource $(az apim show --name ${APIM_NAME} --resource-group ${RESOURCE_GROUP} --query id -o tsv) \
  --workspace $(az monitor log-analytics workspace show --workspace-name la-apim --resource-group ${RESOURCE_GROUP} --query id -o tsv) \
  --logs '[{"category": "GatewayLogs", "enabled": true}, {"category": "WebSocketConnectionLogs", "enabled": true}]' \
  --metrics '[{"category": "AllMetrics", "enabled": true}]'
```

Configure API-level logging:
```xml
<inbound>
    <base />
</inbound>
<backend>
    <base />
</backend>
<outbound>
    <base />
</outbound>
<on-error>
    <base />
</on-error>
```

### Phase 4: Testing and Validation (Week 6-7)

#### 1. Functional Testing

Use Postman collections:
```bash
cd tests/postman

# Update environment variables for APIM
# - APIM_URL: https://apim-migration.azure-api.net
# - SUBSCRIPTION_KEY: your-subscription-key

# Run tests
newman run collection.json -e environment-migration.json --reporters cli,json
```

#### 2. Load Testing

```bash
cd tests/k6

# Configure test script for migrated API
export APIM_URL="https://apim-migration.azure-api.net"
export SUBSCRIPTION_KEY="your-key"

# Run load test
k6 run --vus 100 --duration 300s load-test.js

# Compare results with AWS API Gateway baseline
# Key metrics: latency (p50, p95, p99), throughput, error rate
```

#### 3. Security Testing

- Verify JWT validation works correctly (Cognito tokens)
- Test rate limiting and quotas match AWS behavior
- Validate IP filtering (if applicable)
- Check client certificate validation for mTLS
- Test CORS preflight requests
- Verify API key validation

#### 4. Integration Testing

- Test end-to-end flows with dependent services
- Verify webhook callbacks
- Test async operations
- Validate error handling and gateway responses
- Test request/response transformations
- Verify stage variables migrated to Named Values

## Tooling and Automation

### Recommended Tools

1. **Spectral** - OpenAPI linting
   ```bash
   npm install -g @stoplight/spectral-cli
   spectral lint openapi.yaml --ruleset .spectral.yaml
   ```

2. **Postman/Newman** - API testing
   ```bash
   npm install -g newman
   newman run collection.json -e environment.json
   ```

3. **k6** - Load testing
   ```bash
   brew install k6  # macOS
   # or download from https://k6.io/
   k6 run load-test.js
   ```

4. **AWS CLI** - Export APIs from AWS
   ```bash
   # Install AWS CLI v2
   aws --version
   aws configure
   ```

5. **APIM Import Script** - [../../scripts/import-openapi.sh](../../scripts/import-openapi.sh)

6. **Migration Scripts** - [../../tools/migration/](../../tools/migration/)
   - `translate-openapi-aws.sh` - Clean AWS API Gateway exports
   - `translate-openapi-aws.ps1` - PowerShell version for Windows

### Custom Translation Helpers

See [../../tools/migration/README.md](../../tools/migration/README.md) for:
- OpenAPI cleanup scripts for AWS exports
- Policy translation templates
- Bulk import scripts
- Configuration export/import utilities
- VTL to C#/Liquid conversion examples

## Risk and Compatibility Notes

### Critical Compatibility Issues

#### 1. Path Parameter Encoding

**Issue:** AWS API Gateway and APIM may handle URL encoding differently for path parameters.

**AWS:** `/{proxy+}` matches multi-segment paths
**APIM:** `/*` or explicit path segments

**Mitigation:**
```xml
<inbound>
    <rewrite-uri template="@{
        // Handle greedy path parameters
        return context.Request.OriginalUrl.Path;
    }" copy-unmatched-params="true" />
</inbound>
```

#### 2. Lambda Integration Replacement

**Issue:** Lambda functions cannot be directly called from APIM. Must expose via HTTP endpoint or migrate to Azure Functions.

**Options:**
1. **Lambda Function URLs** (AWS-side):
   - Enable Function URL on Lambda
   - Call from APIM as HTTP backend
   
2. **API Gateway + ALB** (AWS-side):
   - Keep Lambda behind ALB
   - Call ALB endpoint from APIM

3. **Migrate to Azure Functions**:
   - Rewrite Lambda functions as Azure Functions
   - Call directly from APIM

**Mitigation Example:**
```xml
<inbound>
    <base />
    <set-backend-service base-url="https://lambda-url.lambda-url.us-east-1.on.aws" />
    <!-- Add necessary headers for Lambda Function URL -->
    <set-header name="Content-Type" exists-action="override">
        <value>application/json</value>
    </set-header>
</inbound>
```

#### 3. VPC Link to VNet Integration

**Issue:** AWS VPC Links provide access to private resources. APIM requires VNet integration.

**AWS VPC Link:** NLB → Private resources
**APIM:** VNet integration → Private endpoints/resources

**Mitigation:**
- Deploy APIM in VNet or use VNet integration
- Ensure network connectivity to private backends
- Configure NSGs and firewall rules
- Test connectivity before cutover

#### 4. Stage Variables to Named Values

**Issue:** AWS stage variables need to be migrated to APIM Named Values.

**Migration Process:**
```bash
# List stage variables from AWS
aws apigateway get-stage \
  --rest-api-id abc123 \
  --stage-name prod \
  --query 'variables' --output json

# Create Named Values in APIM
az apim nv create \
  --resource-group ${RESOURCE_GROUP} \
  --service-name ${APIM_NAME} \
  --named-value-id backend-url \
  --display-name "Backend URL" \
  --value "https://backend.example.com"
```

Usage in policies:
```xml
<inbound>
    <set-backend-service base-url="{{backend-url}}" />
</inbound>
```

#### 5. Request/Response Mapping with VTL

**Issue:** Velocity Template Language (VTL) is AWS-specific and not supported in APIM.

**Mitigation:** Rewrite transformations using:
- **C# expressions** for complex logic
- **Liquid templates** for simpler transformations
- **set-body policy** with inline code

See mapping examples in [Mapping Guide](#requestresponse-transformation) section.

#### 6. JWT Validation with Cognito

**Issue:** Cognito JWT token validation configuration differs.

**AWS API Gateway:** Built-in Cognito authorizer
**APIM:** Generic JWT validation with OIDC discovery

**Mitigation:**
```xml
<validate-jwt header-name="Authorization" failed-validation-httpcode="401">
    <openid-config url="https://cognito-idp.us-east-1.amazonaws.com/us-east-1_USERPOOLID/.well-known/openid-configuration" />
    <audiences>
        <audience>your-app-client-id</audience>
    </audiences>
    <required-claims>
        <claim name="token_use" match="any">
            <value>access</value>
        </claim>
    </required-claims>
</validate-jwt>
```

Test with actual Cognito tokens before cutover.

#### 7. Throttling Semantics

**Issue:** AWS rate limiting and burst limits work differently than APIM rate limiting.

**AWS:**
- Rate limit: Steady-state requests per second
- Burst limit: Maximum concurrent requests

**APIM:**
- Rate limit: Maximum requests per time period
- Renewal period: Time window for limit

**Mitigation:**
```xml
<!-- Approximate AWS burst behavior -->
<rate-limit-by-key calls="1000" renewal-period="10" 
                   counter-key="@(context.Subscription.Id)" />

<!-- Approximate AWS rate limit -->
<rate-limit-by-key calls="500" renewal-period="1" 
                   counter-key="@(context.Subscription.Id)" />
```

Monitor during testing and adjust as needed.

#### 8. Caching Differences

**Issue:** Cache behavior and key generation differ.

**AWS:** Stage-level cache with method overrides
**APIM:** Operation-level cache with vary-by options

**Mitigation:**
```xml
<cache-lookup vary-by-developer="false" vary-by-developer-groups="false">
    <vary-by-query-parameter>param1</vary-by-query-parameter>
    <vary-by-query-parameter>param2</vary-by-query-parameter>
    <vary-by-header>Accept</vary-by-header>
    <vary-by-header>Authorization</vary-by-header>
</cache-lookup>
```

Test cache hit rates before and after migration.

#### 9. mTLS (Mutual TLS)

**Issue:** mTLS configuration is significantly different.

**AWS:** Certificate configuration in API Gateway settings
**APIM:** Client certificate validation in policies + Key Vault

**Mitigation:**
```xml
<inbound>
    <choose>
        <when condition="@(context.Request.Certificate == null || !context.Request.Certificate.Verify())">
            <return-response>
                <set-status code="403" reason="Invalid client certificate" />
            </return-response>
        </when>
    </choose>
    <!-- Additional certificate validation -->
    <validate-client-certificate validate-revocation="true" validate-trust="true" validate-not-before="true" validate-not-after="true" ignore-error="false" />
</inbound>
```

#### 10. WebSocket APIs

**Issue:** AWS API Gateway supports WebSocket APIs; APIM support is limited.

**Note:** Azure APIM supports WebSocket passthrough but not WebSocket-specific policies.

**Mitigation:**
- For simple WebSocket proxying: Configure backend with WebSocket support
- For complex WebSocket logic: Consider Azure SignalR Service or keep in AWS
- Test WebSocket connections thoroughly

#### 11. Binary Media Types

**Issue:** Binary response handling configuration differs.

**AWS:** Binary media types list in API settings
**APIM:** Content-Type based handling

**Mitigation:**
```xml
<inbound>
    <set-header name="Accept" exists-action="override">
        <value>application/octet-stream</value>
    </set-header>
</inbound>
<outbound>
    <base />
    <!-- Binary responses are automatically handled -->
</outbound>
```

#### 12. Private Integrations and VPC Links

**Issue:** Private backend connectivity architecture differs.

**Mitigation Steps:**
1. Deploy APIM with VNet integration or within VNet
2. Configure private endpoints or ExpressRoute
3. Set up NSG rules for APIM subnet
4. Test connectivity to private backends
5. Configure DNS for private resources

#### 13. CloudWatch Logs to Application Insights

**Issue:** Logging format and query syntax differ.

**AWS CloudWatch Logs:** CloudWatch Logs Insights queries
**Azure:** KQL (Kusto Query Language) in Log Analytics

**Migration:**
- Map log fields to APIM diagnostic logs
- Recreate CloudWatch dashboards in Azure Monitor
- Translate CloudWatch alarms to Azure Monitor alerts
- Update log retention policies

## Testing and Validation

### Test Checklist

- [ ] Functional tests pass (Postman/Newman)
- [ ] Load tests meet performance targets (k6)
- [ ] Latency is within acceptable range (compare to AWS baseline)
- [ ] Security tests pass (authentication, authorization)
- [ ] JWT validation works with Cognito tokens
- [ ] Rate limiting and throttling behave as expected
- [ ] Quota enforcement works correctly
- [ ] Caching works correctly (hit rates, TTL)
- [ ] Request/response transformations produce correct output
- [ ] Error responses match expected format
- [ ] Custom domains resolve correctly
- [ ] SSL/TLS certificates valid and auto-renewal configured
- [ ] Logging captures necessary data
- [ ] Monitoring dashboards show correct metrics
- [ ] Integration tests with dependent services pass
- [ ] Private backend connectivity works (if using VNet)
- [ ] WAF rules migrated and functional (if applicable)
- [ ] mTLS works correctly (if used)

### Performance Validation

Compare before and after metrics:

| Metric | AWS API Gateway | Azure APIM | Delta |
|--------|----------------|------------|-------|
| P50 Latency | | | |
| P95 Latency | | | |
| P99 Latency | | | |
| Error Rate (4xx) | | | |
| Error Rate (5xx) | | | |
| Throughput (req/s) | | | |
| Cache Hit Rate | | | |

Document any deviations and explain or remediate.

### Integration Validation

- [ ] Test with actual clients (not just test tools)
- [ ] Verify mobile app integrations
- [ ] Test web application flows
- [ ] Validate third-party integrations
- [ ] Check webhook deliveries
- [ ] Test async operations and callbacks

## Cutover and Rollback

### Pre-Cutover Checklist

- [ ] All APIs migrated and tested in APIM
- [ ] Lambda integrations replaced or exposed via HTTP
- [ ] Policies and authorizers validated functionally
- [ ] Performance meets or exceeds AWS baseline
- [ ] Monitoring and alerts configured in Azure
- [ ] Custom domains configured with certificates
- [ ] DNS records prepared (low TTL set)
- [ ] API keys/subscriptions created for all consumers
- [ ] Rollback plan tested and documented
- [ ] Team trained on APIM operations and troubleshooting
- [ ] Communication plan ready for API consumers
- [ ] Stakeholder approvals obtained
- [ ] Maintenance window scheduled (if needed)

### DNS Migration Strategy

**Option 1: Blue/Green with DNS Switching**
```bash
# Current: api.example.com → AWS API Gateway
# New: api-new.example.com → Azure APIM

# Step 1: Deploy to new subdomain and test
# Step 2: Lower TTL on api.example.com to 60 seconds
# Step 3: Update DNS to point api.example.com to APIM
# Step 4: Monitor for 24-48 hours
# Step 5: Decommission AWS API Gateway
```

**Option 2: Weighted DNS (Gradual Traffic Shift)**
```bash
# Use Route 53 weighted routing or Azure Traffic Manager

# Week 1: 10% traffic to APIM, 90% to AWS
# Week 2: 25% traffic to APIM, 75% to AWS
# Week 3: 50% traffic to APIM, 50% to AWS
# Week 4: 100% traffic to APIM
# Week 5: Decommission AWS API Gateway
```

**Option 3: API Version Path**
```bash
# Old: api.example.com/v1/* → AWS API Gateway
# New: api.example.com/v2/* → Azure APIM

# Gradually migrate consumers to v2
# Provide migration guide to API consumers
# Set deprecation timeline for v1
```

### Cutover Steps

1. **T-24 hours:** Final smoke tests on APIM
2. **T-2 hours:** Lower DNS TTL to 60 seconds
3. **T-1 hour:** Final validation and team briefing
4. **T-30 min:** Notify consumers of upcoming change
5. **T-15 min:** Put AWS API Gateway in read-only mode (if possible)
6. **T-5 min:** Final checks, team on standby
7. **T-0:** Update DNS record to point to APIM
8. **T+2 min:** Verify DNS propagation
9. **T+5 min:** Monitor APIM metrics and logs
10. **T+10 min:** Verify traffic is flowing correctly
11. **T+30 min:** Run smoke tests against APIM
12. **T+1 hour:** Confirm no major issues, continue monitoring
13. **T+4 hours:** Check error rates and performance
14. **T+24 hours:** Review metrics, error rates, performance
15. **T+1 week:** Final validation and AWS resource cleanup

### Rollback Plan

**If issues detected within 24 hours:**

1. **Immediate rollback (< 5 minutes):**
   ```bash
   # Revert DNS to point back to AWS API Gateway
   # Update A/CNAME record: api.example.com → [aws-gateway-url]
   
   # Using Route 53
   aws route53 change-resource-record-sets \
     --hosted-zone-id Z123456 \
     --change-batch file://rollback-dns.json
   ```

2. **Monitor AWS API Gateway:**
   - Verify traffic is flowing correctly
   - Check CloudWatch metrics
   - Confirm error rates return to normal
   - Verify performance is acceptable

3. **Communicate:**
   - Notify stakeholders of rollback
   - Provide incident summary
   - Schedule post-mortem

4. **Investigate:**
   - Review APIM logs in Log Analytics
   - Check Application Insights telemetry
   - Identify root cause
   - Remediate issues
   - Schedule retry of cutover

**Rollback Decision Criteria:**
- Error rate > 5% for more than 10 minutes
- P95 latency > 2x baseline
- Complete service outage
- Critical functionality broken
- Security vulnerability discovered

### Post-Migration Activities

- [ ] Monitor for 7 days post-cutover
- [ ] Collect feedback from API consumers
- [ ] Optimize policies based on actual traffic patterns
- [ ] Review costs and adjust APIM tier if needed
  - Compare actual usage with tier pricing (especially for v2 consumption-based tiers)
  - Consider tier migration if usage patterns warrant it
  - Use Azure Cost Management for detailed cost analysis
- [ ] Fine-tune monitoring and alerts
- [ ] Update documentation and runbooks
- [ ] Decommission AWS API Gateway stages
- [ ] Remove AWS resources (after retention period)
- [ ] Conduct post-mortem and document lessons learned
- [ ] Update disaster recovery procedures
- [ ] Archive AWS CloudWatch logs (if needed)
- [ ] Cancel AWS VPC Links and NLBs (if no longer needed)

## Additional Resources

- [Azure APIM Documentation](https://learn.microsoft.com/azure/api-management/)
- [Policy Reference](https://learn.microsoft.com/azure/api-management/api-management-policies)
- [AWS to Azure Services Comparison](https://learn.microsoft.com/azure/architecture/aws-professional/services)
- [Labs](../../labs/README.md) - Hands-on learning
- [Policy Examples](../../policies/) - Reference implementations
- [Migration Tools](../../tools/migration/) - Scripts and utilities
- [AWS API Gateway Documentation](https://docs.aws.amazon.com/apigateway/)

## Support and Questions

For questions or assistance with migration:
- Open an issue on [GitHub](https://github.com/jonathandhaene/apim-educational/issues)
- Review [troubleshooting guide](../troubleshooting.md)
- Consult [Azure support](https://azure.microsoft.com/support/)
- AWS to Azure migration resources: [Azure Migration Center](https://azure.microsoft.com/migration/)

---

**Good luck with your migration!** 🚀 This guide is continuously updated based on real-world migrations. Please contribute improvements and lessons learned.
