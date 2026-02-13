# Migrating from Google API Services to Azure API Management

This guide provides a comprehensive roadmap for migrating from Google's API services (Apigee API Management and Google Cloud API Gateway) to Azure API Management (APIM).

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

**Google Apigee:**
```bash
# List all API proxies
apigee-cli apis list --organization your-org

# Export proxy configurations
for proxy in $(apigee-cli apis list -o your-org); do
  apigee-cli apis export -o your-org -n $proxy -f ${proxy}.zip
done
```

**Google Cloud API Gateway:**
```bash
# List API configs
gcloud api-gateway apis list

# List gateways
gcloud api-gateway gateways list

# Export API config
gcloud api-gateway api-configs describe CONFIG_NAME \
  --api=API_NAME --format=json > api-config.json
```

Create an inventory spreadsheet with:
- API Name
- Number of operations/endpoints
- Current traffic volume (requests/day)
- Authentication method (API key, OAuth, JWT)
- Rate limits and quotas
- Dependencies on other services

#### 2. Products and API Keys

**Document:**
- Number of API products
- Subscription tiers and quotas
- API key distribution method
- Key rotation policies
- Developer portal customizations

#### 3. Quotas and Rate Limits

**Identify:**
- Per-key rate limits (requests/second, requests/day)
- Global rate limits
- Quota enforcement mechanisms
- Spike arrest configurations

#### 4. Authentication and Authorization

**Document current auth patterns:**
- API keys (simple, OAuth scopes)
- OAuth 2.0 flows (client credentials, authorization code, implicit)
- JWT validation (issuers, audiences, claims)
- mTLS (mutual TLS) configurations
- SAML integration

#### 5. Logging and Analytics

**Current setup:**
- Logging destinations (Cloud Logging, BigQuery, third-party)
- Metrics collected (latency, error rates, traffic)
- Analytics dashboards and reports
- Alert configurations

#### 6. Custom Domains and Certificates

**Inventory:**
- Custom domain names
- SSL/TLS certificates (expiration dates, CA)
- DNS configurations
- Certificate renewal processes

#### 7. Monetization

**If using Apigee monetization:**
- Pricing models (pay-per-use, tiered)
- Billing integration
- Revenue sharing arrangements
- Transaction records

#### 8. Developer Portal

**Document:**
- Portal customization (branding, content)
- Self-service registration workflow
- API documentation format
- Code samples and SDKs

## Mapping Guide

### Core Concepts Mapping

| Google Apigee/API Gateway | Azure APIM | Notes |
|---------------------------|------------|-------|
| API Proxy | API | Container for operations |
| API Product | Product | Bundle of APIs with access control |
| Proxy Endpoint | API Operation | Individual endpoint/method |
| Target Endpoint | Backend | Backend service URL |
| Policy | Policy | Request/response processing logic |
| API Key | Subscription Key | Access credential |
| Developer App | Subscription | App registration with key |
| Environment | Named Values / Environment | Configuration variables |
| Flow | Policy Section | inbound/backend/outbound/on-error |
| Quota | Quota Policy | Request limits per time period |
| Spike Arrest | Rate Limit Policy | Smoothing traffic spikes |
| Response Cache | Cache Policy | Response caching |
| API Analytics | Application Insights | Monitoring and analytics |
| Developer Portal | Developer Portal | Self-service API docs |

### Policy Mapping

#### Google Apigee Policies → Azure APIM Policies

| Apigee Policy | APIM Policy | Implementation |
|---------------|-------------|----------------|
| VerifyAPIKey | subscription-required | Built-in subscription validation |
| OAuthV2 | validate-jwt | JWT validation with OAuth providers |
| Quota | quota / quota-by-key | Time-based request limits |
| SpikeArrest | rate-limit / rate-limit-by-key | Request rate smoothing |
| ResponseCache | cache-lookup / cache-store | Response caching |
| AssignMessage | set-header / set-body | Message transformation |
| Javascript | set-variable / C# expressions | Policy expressions |
| ServiceCallout | send-request | Call external service |
| RaiseFault | return-response | Return error response |
| JSONtoXML | xml-to-json / json-to-xml | Format transformation |
| ExtractVariables | set-variable | Extract from request/response |
| AssignMessage | set-query-parameter | Modify query strings |
| BasicAuthentication | authentication-basic | Basic auth header |
| XMLThreatProtection | validate-content | Content validation |
| JSONThreatProtection | validate-content | JSON schema validation |
| CORS | cors | Cross-origin requests |
| AccessControl | ip-filter | IP whitelisting/blacklisting |

#### Google Cloud API Gateway → Azure APIM

| API Gateway Feature | APIM Equivalent | Notes |
|---------------------|-----------------|-------|
| OpenAPI Spec | OpenAPI Import | Direct import supported |
| API Config | API Definition | Stored in APIM |
| Backend Address | Backend URL | Set in policy or backend config |
| Authentication | validate-jwt / subscription | Multiple auth options |
| Path Translation | rewrite-uri | URL rewriting policy |
| CORS | cors | CORS policy |

### Authentication Mapping

#### API Key Authentication

**Apigee:**
```xml
<VerifyAPIKey async="false" continueOnError="false" enabled="true" name="Verify-API-Key">
    <APIKey ref="request.queryparam.apikey"/>
</VerifyAPIKey>
```

**APIM:**
```xml
<inbound>
    <base />
    <!-- API key validation is automatic via subscription key -->
    <!-- Custom header location: -->
    <check-header name="X-API-Key" failed-check-httpcode="401" failed-check-error-message="API key missing or invalid" ignore-case="true">
        <value>{{valid-api-key}}</value>
    </check-header>
</inbound>
```

#### OAuth 2.0 / JWT

**Apigee:**
```xml
<OAuthV2 async="false" continueOnError="false" enabled="true" name="OAuth-v20-1">
    <Operation>VerifyAccessToken</Operation>
</OAuthV2>
```

**APIM:**
```xml
<inbound>
    <base />
    <validate-jwt header-name="Authorization" failed-validation-httpcode="401">
        <openid-config url="https://login.microsoftonline.com/{tenant-id}/v2.0/.well-known/openid-configuration" />
        <audiences>
            <audience>api://your-api-id</audience>
        </audiences>
        <required-claims>
            <claim name="scope" match="all">
                <value>read</value>
                <value>write</value>
            </claim>
        </required-claims>
    </validate-jwt>
</inbound>
```

#### Rate Limiting

**Apigee Quota:**
```xml
<Quota async="false" continueOnError="false" enabled="true" name="Quota-1">
    <Allow count="10000" countRef="verifyapikey.Verify-API-Key.developer.quota.limit"/>
    <Interval>1</Interval>
    <TimeUnit>month</TimeUnit>
</Quota>
```

**APIM Quota:**
```xml
<inbound>
    <base />
    <quota-by-key calls="10000" 
                  renewal-period="2592000" 
                  counter-key="@(context.Subscription.Id)" />
</inbound>
```

**Apigee Spike Arrest:**
```xml
<SpikeArrest name="Spike-Arrest-1">
    <Rate>100ps</Rate>
</SpikeArrest>
```

**APIM Rate Limit:**
```xml
<inbound>
    <base />
    <rate-limit-by-key calls="100" 
                       renewal-period="1" 
                       counter-key="@(context.Subscription.Id)" />
</inbound>
```

## Migration Plan

### Phase 1: Planning and Design (Week 1-2)

#### Activities:
1. ✅ Complete assessment (inventory all APIs)
2. ✅ Design APIM architecture (tier, networking, regions)
3. ✅ Map policies and authentication patterns
4. ✅ Plan DNS and domain migration strategy
5. ✅ Define rollback procedures
6. ✅ Set up Azure environment and APIM instance

#### Deliverables:
- Migration architecture document
- Policy mapping spreadsheet
- Risk assessment and mitigation plan
- Test plan and success criteria

### Phase 2: Infrastructure Setup (Week 2-3)

#### Activities:
1. Deploy APIM instance (consider Developer tier for testing)
2. Configure networking (VNet, private endpoints if needed)
3. Set up Application Insights and Log Analytics
4. Configure Azure Key Vault for secrets
5. Set up CI/CD pipeline for APIM deployments
6. Deploy IaC templates (Bicep/Terraform)

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

**1. Export OpenAPI Specifications**

From Google Cloud API Gateway:
```bash
# Export OpenAPI spec
gcloud api-gateway api-configs describe CONFIG_NAME \
  --api=API_NAME \
  --format=json | jq '.openapiDocuments[0].document' > openapi.yaml

# Validate OpenAPI spec
spectral lint openapi.yaml
```

From Apigee (generate from API proxy):
```bash
# Use Apigee2OpenAPI tool or manual extraction
# Export API proxy bundle and extract swagger/openapi definition
```

**2. Lint and Clean OpenAPI Specs**

Use the provided tooling:
```bash
cd tools/migration

# Lint with Spectral
spectral lint --ruleset ../../.spectral.yaml openapi.yaml

# Fix common issues
./translate-openapi.sh openapi.yaml openapi-cleaned.yaml
```

**3. Import APIs to APIM**

```bash
# Set variables
RESOURCE_GROUP="rg-apim-migration"
APIM_NAME="apim-migration"
API_ID="migrated-api"

# Import OpenAPI spec
./scripts/import-openapi.sh

# Or use Azure CLI directly
az apim api import \
  --resource-group ${RESOURCE_GROUP} \
  --service-name ${APIM_NAME} \
  --api-id ${API_ID} \
  --path /api/v1 \
  --specification-format OpenApiJson \
  --specification-path openapi-cleaned.yaml \
  --display-name "Migrated API"
```

**4. Translate Policies**

Manual policy translation is required. Use the mapping guide above.

Example Apigee policy:
```xml
<AssignMessage name="Add-CORS">
  <Set>
    <Headers>
      <Header name="Access-Control-Allow-Origin">*</Header>
      <Header name="Access-Control-Allow-Methods">GET, POST, PUT, DELETE</Header>
    </Headers>
  </Set>
</AssignMessage>
```

Equivalent APIM policy:
```xml
<inbound>
    <cors>
        <allowed-origins>
            <origin>*</origin>
        </allowed-origins>
        <allowed-methods>
            <method>GET</method>
            <method>POST</method>
            <method>PUT</method>
            <method>DELETE</method>
        </allowed-methods>
    </cors>
</inbound>
```

**5. Configure Backends**

```bash
# Create backend
az apim backend create \
  --resource-group ${RESOURCE_GROUP} \
  --service-name ${APIM_NAME} \
  --backend-id legacy-backend \
  --url "https://api.example.com" \
  --protocol http \
  --description "Legacy backend service"

# Configure in policy
```

```xml
<inbound>
    <base />
    <set-backend-service backend-id="legacy-backend" />
</inbound>
```

**6. Migrate Custom Domains and Certificates**

```bash
# Upload certificate to Key Vault
KV_NAME="kv-apim-migration"
az keyvault certificate import \
  --vault-name ${KV_NAME} \
  --name api-custom-domain \
  --file certificate.pfx \
  --password "cert-password"

# Configure custom domain in APIM
# Navigate to: APIM → Custom domains → Add
# Or use ARM/Bicep template
```

**7. Configure Authentication**

Set up Named Values for secrets:
```bash
# Add API keys from Key Vault
az apim nv create \
  --resource-group ${RESOURCE_GROUP} \
  --service-name ${APIM_NAME} \
  --named-value-id backend-api-key \
  --display-name "Backend API Key" \
  --secret true \
  --key-vault-secret-id "https://${KV_NAME}.vault.azure.net/secrets/backend-api-key"
```

**8. Set Up Logging**

```bash
# Link Application Insights
# Already done in infrastructure setup

# Configure diagnostic settings
az monitor diagnostic-settings create \
  --name apim-logs \
  --resource $(az apim show --name ${APIM_NAME} --resource-group ${RESOURCE_GROUP} --query id -o tsv) \
  --workspace $(az monitor log-analytics workspace show --workspace-name la-apim --resource-group ${RESOURCE_GROUP} --query id -o tsv) \
  --logs '[{"category": "GatewayLogs", "enabled": true}]'
```

### Phase 4: Testing and Validation (Week 6-7)

#### 1. Functional Testing

Use Postman collections:
```bash
cd tests/postman

# Import collection
# Update environment variables
# Run tests
newman run collection.json -e environment-migration.json
```

#### 2. Load Testing

```bash
cd tests/k6

# Configure test script for migrated API
export APIM_URL="https://apim-migration.azure-api.net"
export SUBSCRIPTION_KEY="your-key"

# Run load test
k6 run --vus 100 --duration 300s load-test.js

# Compare results with Google API baseline
```

#### 3. Security Testing

- Verify JWT validation works correctly
- Test rate limiting and quotas
- Validate IP filtering (if applicable)
- Check certificate validation for mTLS

#### 4. Integration Testing

- Test end-to-end flows with dependent services
- Verify webhook callbacks
- Test async operations
- Validate error handling

### Phase 5: Cutover and Go-Live (Week 8)

#### Pre-Cutover Checklist:

- [ ] All APIs migrated and tested
- [ ] Policies validated functionally
- [ ] Performance meets or exceeds baseline
- [ ] Monitoring and alerts configured
- [ ] Custom domains configured with certificates
- [ ] Developer portal updated with new documentation
- [ ] API keys generated for all consumers
- [ ] Rollback plan tested
- [ ] Team trained on APIM operations
- [ ] Communication plan ready for API consumers

#### DNS Migration Strategy:

**Option 1: Blue/Green with DNS Switching**
```bash
# Current: api.example.com → Google API Gateway/Apigee
# New: api-new.example.com → Azure APIM

# Step 1: Deploy to new subdomain
# Step 2: Test thoroughly
# Step 3: Update DNS to point api.example.com to APIM
# Step 4: Monitor for 24-48 hours
# Step 5: Decommission Google resources
```

**Option 2: Weighted DNS (gradual traffic shift)**
```bash
# Use Traffic Manager or Route53 (if multi-cloud)
# Week 1: 10% traffic to APIM, 90% to Google
# Week 2: 50% traffic to APIM, 50% to Google
# Week 3: 100% traffic to APIM
# Week 4: Decommission Google
```

**Option 3: API Version Path**
```bash
# Old: api.example.com/v1/* → Google
# New: api.example.com/v2/* → Azure APIM
# Gradually migrate consumers to v2
```

#### Cutover Steps:

1. **T-1 hour:** Final smoke tests on APIM
2. **T-30 min:** Lower DNS TTL to 60 seconds
3. **T-15 min:** Notify consumers of upcoming change
4. **T-0:** Update DNS CNAME to point to APIM
5. **T+5 min:** Monitor APIM metrics and logs
6. **T+30 min:** Verify traffic is flowing correctly
7. **T+2 hours:** Confirm no major issues, begin detailed monitoring
8. **T+24 hours:** Review metrics, error rates, performance
9. **T+1 week:** Decommission Google API resources

## Tooling and Automation

### Recommended Tools

1. **Spectral** - OpenAPI linting
   ```bash
   npm install -g @stoplight/spectral-cli
   spectral lint openapi.yaml
   ```

2. **Postman/Newman** - API testing
   ```bash
   npm install -g newman
   newman run collection.json -e environment.json
   ```

3. **k6** - Load testing
   ```bash
   brew install k6  # macOS
   k6 run load-test.js
   ```

4. **APIM Import Script** - [../../scripts/import-openapi.sh](../../scripts/import-openapi.sh)

5. **Migration Scripts** - [../../tools/migration/](../../tools/migration/)

### Custom Translation Helpers

See [../../tools/migration/README.md](../../tools/migration/README.md) for:
- OpenAPI cleanup scripts
- Policy translation templates
- Bulk import scripts
- Configuration export/import utilities

## Risk and Compatibility Notes

### Critical Compatibility Issues

#### 1. HTTP Header Case Sensitivity

**Issue:** Google API Gateway/Apigee may handle headers case-insensitively, but backend services might be case-sensitive.

**Mitigation:**
```xml
<inbound>
    <!-- Normalize header case -->
    <set-header name="Content-Type" exists-action="override">
        <value>@(context.Request.Headers.GetValueOrDefault("content-type", "application/json"))</value>
    </set-header>
</inbound>
```

#### 2. Path Rewriting Differences

**Issue:** URL path transformation syntax differs between platforms.

**Apigee:**
```xml
<AssignMessage>
  <AssignTo createNew="false" transport="http" type="request"/>
  <Set>
    <Path>/v2{request.path}</Path>
  </Set>
</AssignMessage>
```

**APIM:**
```xml
<inbound>
    <rewrite-uri template="/v2{context.Request.OriginalUrl.Path}" />
</inbound>
```

#### 3. JWT Provider Differences

**Issue:** Token validation configuration syntax differs.

**Mitigation:** Carefully map issuer, audience, and claims validation. Test thoroughly with actual tokens.

#### 4. mTLS Configuration

**Issue:** Mutual TLS setup differs significantly.

**Apigee:** Uses TrustStore and KeyStore
**APIM:** Uses certificates in Key Vault

**Mitigation:** Test mTLS carefully in non-production first. Document certificate chain requirements.

#### 5. Rate Limit Semantics

**Issue:** Spike Arrest vs Rate Limit behave differently.
- **Spike Arrest:** Smooths traffic (e.g., 100ps = 1 per 10ms)
- **Rate Limit:** Hard limit over a period (e.g., 100 per minute)

**Mitigation:** May need to adjust limits to achieve similar behavior. Monitor during testing phase.

#### 6. Cache Behavior

**Issue:** Cache key generation and invalidation may differ.

**Mitigation:**
```xml
<cache-lookup vary-by-developer="false" vary-by-developer-groups="false">
    <vary-by-query-parameter>param1</vary-by-query-parameter>
    <vary-by-query-parameter>param2</vary-by-query-parameter>
    <vary-by-header>Accept</vary-by-header>
</cache-lookup>
```

Test cache hit rates before and after migration.

#### 7. CORS Handling

**Issue:** CORS preflight handling may need explicit configuration.

**APIM:**
```xml
<cors allow-credentials="true">
    <allowed-origins>
        <origin>https://example.com</origin>
    </allowed-origins>
    <allowed-methods preflight-result-max-age="300">
        <method>GET</method>
        <method>POST</method>
        <method>PUT</method>
        <method>DELETE</method>
    </allowed-methods>
    <allowed-headers>
        <header>*</header>
    </allowed-headers>
    <expose-headers>
        <header>*</header>
    </expose-headers>
</cors>
```

#### 8. Timeout Configurations

**Issue:** Default timeouts may differ.

**APIM:** Default is 30 seconds for backend calls.

**Mitigation:**
```xml
<inbound>
    <base />
    <set-backend-service base-url="https://backend.example.com" />
</inbound>
<backend>
    <forward-request timeout="60" />
</backend>
```

#### 9. Quota vs Rate Limit

**Apigee Quota:** Accumulated over period (e.g., 10,000 per month)
**APIM Quota:** Similar but may reset differently

**Mitigation:** Use `quota-by-key` with appropriate renewal period (2592000 seconds = 30 days).

## Testing and Validation

### Test Checklist

- [ ] Functional tests pass (Postman/Newman)
- [ ] Load tests meet performance targets (k6)
- [ ] Security tests pass (authentication, authorization)
- [ ] Rate limiting behaves as expected
- [ ] Caching works correctly
- [ ] Error responses match expected format
- [ ] Custom domains resolve correctly
- [ ] SSL/TLS certificates valid
- [ ] Logging captures necessary data
- [ ] Monitoring dashboards show correct metrics
- [ ] Integration tests with dependent services pass

### Performance Validation

Compare before and after metrics:
- P50, P95, P99 latency
- Error rate (2xx, 4xx, 5xx)
- Throughput (requests/second)
- Cache hit rate

Document any deviations and explain or remediate.

## Cutover and Rollback

### Rollback Plan

**If issues detected within 24 hours:**

1. **Immediate rollback (< 5 minutes):**
   ```bash
   # Revert DNS to point back to Google
   # Update CNAME record: api.example.com → [google-gateway-url]
   ```

2. **Monitor Google APIs:**
   - Verify traffic is flowing correctly
   - Check error rates return to normal
   - Confirm performance is acceptable

3. **Communicate:**
   - Notify stakeholders of rollback
   - Provide incident report
   - Schedule post-mortem

4. **Investigate:**
   - Review APIM logs and metrics
   - Identify root cause
   - Remediate issues
   - Schedule retry of cutover

### Post-Migration Activities

- [ ] Monitor for 7 days post-cutover
- [ ] Collect feedback from API consumers
- [ ] Optimize policies based on actual traffic patterns
- [ ] Review costs and adjust tier if needed
- [ ] Update documentation and runbooks
- [ ] Decommission Google API resources
- [ ] Conduct post-mortem and document lessons learned

## Additional Resources

- [Azure APIM Documentation](https://learn.microsoft.com/azure/api-management/)
- [Policy Reference](https://learn.microsoft.com/azure/api-management/api-management-policies)
- [Apigee to APIM Comparison](https://learn.microsoft.com/azure/architecture/guide/technology-choices/api-management)
- [Labs](../../labs/README.md) - Hands-on learning
- [Policy Examples](../../policies/) - Reference implementations
- [Migration Tools](../../tools/migration/) - Scripts and utilities

## Support and Questions

For questions or assistance with migration:
- Open an issue on [GitHub](https://github.com/jonathandhaene/apim-educational/issues)
- Review [troubleshooting guide](../troubleshooting.md)
- Consult [Azure support](https://azure.microsoft.com/support/)

---

**Good luck with your migration!** 🚀 This guide is continuously updated based on real-world migrations. Please contribute improvements and lessons learned.
