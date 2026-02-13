# API Management Policy Examples

This directory contains a curated collection of Azure API Management policy examples and best practices.

## 📁 Directory Structure

```
policies/
├── jwt-validate.xml        # JWT token validation (Azure AD)
├── rate-limit.xml          # Rate limiting and quotas
├── cache.xml               # Response caching
├── retry.xml               # Retry with exponential backoff
├── transform.xml           # Request/response transformation
├── ip-filter.xml           # IP address filtering
├── mtls.xml                # Mutual TLS (client certificates)
├── ai-gateway.xml          # AI/LLM API gateway
└── fragments/              # Reusable policy fragments
    └── common-headers.xml  # Standard headers fragment
```

## 🎯 Policy Categories

### Authentication & Authorization
- **jwt-validate.xml**: Validate JWT tokens from Microsoft Entra ID (Azure AD)
- **mtls.xml**: Client certificate authentication (mutual TLS)

### Traffic Management
- **rate-limit.xml**: Rate limiting, quotas, throttling
- **ip-filter.xml**: IP whitelist/blacklist

### Performance
- **cache.xml**: Response caching strategies
- **retry.xml**: Retry logic with exponential backoff

### Transformation
- **transform.xml**: Request/response transformation, format conversion

### AI/ML
- **ai-gateway.xml**: AI Gateway for Azure OpenAI and LLM APIs

### Reusable Components
- **fragments/**: Policy fragments for reusability

## 🚀 Quick Start

### Apply a Policy to an API

**Via Azure Portal:**
1. Navigate to API Management → APIs
2. Select your API → Design tab
3. Select an operation (or "All operations")
4. Click the `</>` icon in the Inbound/Outbound/Backend/On-Error section
5. Paste policy XML
6. Save

**Via Azure CLI:**
```bash
# Apply policy to an API
az apim api policy create \
  --resource-group rg-apim \
  --service-name apim-instance \
  --api-id my-api \
  --policy-content @policies/jwt-validate.xml

# Apply policy to a specific operation
az apim api operation policy create \
  --resource-group rg-apim \
  --service-name apim-instance \
  --api-id my-api \
  --operation-id get-users \
  --policy-content @policies/cache.xml
```

**Via Bicep:**
```bicep
resource apiPolicy 'Microsoft.ApiManagement/service/apis/policies@2023-05-01-preview' = {
  parent: api
  name: 'policy'
  properties: {
    value: loadTextContent('policies/jwt-validate.xml')
    format: 'rawxml'
  }
}
```

### Policy Scopes

Policies can be applied at different scopes (in order of precedence):

1. **Global**: Applies to all APIs
2. **Product**: Applies to all APIs in a product
3. **API**: Applies to all operations in an API
4. **Operation**: Applies to a specific operation

**Scope Hierarchy:**
```
Global Policy
    ↓ <base />
Product Policy
    ↓ <base />
API Policy
    ↓ <base />
Operation Policy
```

Use `<base />` to inherit policies from parent scope.

## 📖 Policy Structure

Every policy has four sections:

```xml
<policies>
  <inbound>
    <!-- Executed on incoming requests (before backend call) -->
    <!-- Common: authentication, rate limiting, transformation -->
  </inbound>
  
  <backend>
    <!-- Controls backend call -->
    <!-- Common: retry logic, load balancing, timeouts -->
  </backend>
  
  <outbound>
    <!-- Executed on outgoing responses (after backend call) -->
    <!-- Common: caching, transformation, CORS -->
  </outbound>
  
  <on-error>
    <!-- Executed when error occurs in any section -->
    <!-- Common: error formatting, logging, fallback responses -->
  </on-error>
</policies>
```

## 🔧 Common Patterns

### Pattern 1: Secure Public API

```xml
<policies>
  <inbound>
    <base />
    <validate-jwt header-name="Authorization" />
    <rate-limit calls="100" renewal-period="60" />
    <cache-lookup vary-by-developer="false" />
  </inbound>
  <backend>
    <retry condition="@(context.Response.StatusCode >= 500)" count="3" interval="1" />
  </backend>
  <outbound>
    <base />
    <cache-store duration="3600" />
  </outbound>
</policies>
```

### Pattern 2: Internal API with IP Filtering

```xml
<policies>
  <inbound>
    <base />
    <ip-filter action="allow">
      <address-range from="10.0.0.0" to="10.255.255.255" />
    </ip-filter>
    <check-header name="X-Internal-Key" />
  </inbound>
</policies>
```

### Pattern 3: B2B API with mTLS

```xml
<policies>
  <inbound>
    <base />
    <choose>
      <when condition="@(context.Request.Certificate == null || !context.Request.Certificate.Verify())">
        <return-response>
          <set-status code="403" />
        </return-response>
      </when>
    </choose>
  </inbound>
</policies>
```

## 🧪 Testing Policies

### Test in Azure Portal

1. Navigate to API → Test tab
2. Select operation
3. View "Trace" to see policy execution

### Test with cURL

```bash
# Test JWT validation
curl -H "Authorization: Bearer <token>" \
     -H "Ocp-Apim-Subscription-Key: <key>" \
     https://apim-instance.azure-api.net/api/endpoint

# Test rate limiting
for i in {1..150}; do
  curl -H "Ocp-Apim-Subscription-Key: <key>" \
       https://apim-instance.azure-api.net/api/endpoint
done

# Test caching
curl -v https://apim-instance.azure-api.net/api/endpoint | grep "X-Cache"
```

### Enable Policy Tracing

**Important**: Only enable in dev/test environments (security risk in production)

```bash
# Enable tracing for a subscription
az apim api diagnostic create \
  --resource-group rg-apim \
  --service-name apim-instance \
  --api-id my-api \
  --diagnostic-id applicationinsights \
  --always-log allErrors \
  --sampling-type fixed \
  --sampling-percentage 100
```

Then add `Ocp-Apim-Trace: true` header to requests and check `Ocp-Apim-Trace-Location` response header for trace URL.

## 📝 Policy Expressions

Policies support C# expressions using `@()` or `@{}` syntax:

```xml
<!-- Inline expression -->
<set-header name="X-User-Id" exists-action="override">
  <value>@(context.User.Id)</value>
</set-header>

<!-- Block expression -->
<set-body>@{
  var body = context.Request.Body.As<JObject>(preserveContent: true);
  body["timestamp"] = DateTime.UtcNow;
  return body.ToString();
}</set-body>
```

**Available Context Properties:**
- `context.Request`: Request details (headers, body, URL, method, IP)
- `context.Response`: Response details (statuscode, headers, body)
- `context.User`: User identity (if authenticated)
- `context.Subscription`: Subscription details
- `context.Api`: API metadata
- `context.Operation`: Operation metadata
- `context.Product`: Product metadata
- `context.Variables`: Custom variables
- `context.Elapsed`: Request processing time

## 🔐 Security Best Practices

1. **Never hardcode secrets**: Use Named Values backed by Key Vault
2. **Validate inputs**: Check headers, query params, body
3. **Implement rate limiting**: Protect against abuse
4. **Use HTTPS only**: Enforce TLS 1.2+
5. **Log security events**: Authentication failures, rate limit violations
6. **Principle of least privilege**: Apply policies at narrowest scope
7. **Defense in depth**: Combine multiple security policies
8. **Regular audits**: Review policies for security issues
9. **Test policies**: Verify behavior matches expectations
10. **Document exceptions**: If deviating from standards, document why

## 🎓 Learning Resources

- [Official Policy Reference](https://learn.microsoft.com/azure/api-management/api-management-policies)
- [Policy Expressions](https://learn.microsoft.com/azure/api-management/api-management-policy-expressions)
- [Error Handling](https://learn.microsoft.com/azure/api-management/api-management-error-handling-policies)
- [Transformation Policies](https://learn.microsoft.com/azure/api-management/api-management-transformation-policies)

## 🤝 Contributing

To add a new policy example:

1. Create XML file with descriptive name
2. Include comprehensive comments explaining:
   - Purpose and use case
   - Parameters and configuration
   - Best practices
   - Testing instructions
3. Add entry to this README
4. Test policy in dev environment
5. Submit pull request

## 📊 Policy Performance

**Typical Latency Impact:**
- Header manipulation: <1ms
- JWT validation: 1-5ms
- Rate limiting: <1ms
- JSON parsing: 5-20ms
- Caching (hit): <1ms
- Caching (miss): 0ms overhead
- External service call (send-request): 50-500ms
- Complex transformation: 20-100ms

**Optimization Tips:**
- Minimize external service calls
- Cache transformation results
- Use early return for quick rejections
- Profile with Application Insights
- Avoid complex expressions in loops

## ❓ Troubleshooting

**Policy not applied:**
- Check scope hierarchy (<base /> tags)
- Verify XML is valid
- Check policy execution order

**Policy error:**
- Enable tracing to see detailed execution
- Check Application Insights for errors
- Validate expressions in isolation

**Performance issues:**
- Profile with Application Insights
- Check for N+1 problems (repeated calls)
- Optimize expressions
- Use caching where appropriate

---

**Questions?** Open an issue or see [troubleshooting guide](../docs/troubleshooting.md)
