# Azure API Management Security Guide

This comprehensive guide covers security best practices, authentication patterns, and policy configurations for Azure API Management.

## Table of Contents
- [Security Layers](#security-layers)
- [Authentication Methods](#authentication-methods)
- [Authorization Patterns](#authorization-patterns)
- [TLS and Certificates](#tls-and-certificates)
- [Secrets Management](#secrets-management)
- [Policy-Based Security](#policy-based-security)
- [Network Security](#network-security)
- [Compliance and Auditing](#compliance-and-auditing)

## Security Layers

Azure APIM implements defense-in-depth security across multiple layers:

```
1. Network Layer    → VNet, NSG, Private Endpoints, IP Filtering
2. Transport Layer  → TLS 1.2+, mTLS, Certificate validation
3. Authentication   → Subscription keys, JWT, OAuth, Client certs
4. Authorization    → RBAC, Policy-based access control
5. Application Layer→ Input validation, Rate limiting, WAF
6. Audit Layer      → Diagnostic logs, Application Insights
```

## Authentication Methods

### 1. Subscription Keys (API Keys)

Simplest authentication method; each subscription has a primary and secondary key.

**Use cases:**
- Internal APIs
- Development/testing
- Low-sensitivity data
- Simple client applications

**Best practices:**
- Rotate keys regularly
- Use header (`Ocp-Apim-Subscription-Key`) over query string
- Implement key regeneration process
- Store keys in Key Vault on client side

**Policy Example:**
```xml
<policies>
  <inbound>
    <base />
    <!-- Subscription key is validated automatically -->
    <check-header name="Ocp-Apim-Subscription-Key" failed-check-httpcode="401" failed-check-error-message="Missing or invalid subscription key" />
  </inbound>
</policies>
```

**Securing Subscription Keys:**
```xml
<!-- Require header instead of query string -->
<policies>
  <inbound>
    <choose>
      <when condition="@(context.Request.Headers.GetValueOrDefault("Ocp-Apim-Subscription-Key","") == "")">
        <return-response>
          <set-status code="401" reason="Unauthorized" />
          <set-body>Subscription key must be provided in header</set-body>
        </return-response>
      </when>
    </choose>
  </inbound>
</policies>
```

### 2. OAuth 2.0 / OpenID Connect

Industry-standard authentication using JWT tokens from identity providers.

**Identity Providers:**
- Microsoft Entra ID (Azure AD)
- Auth0
- Okta
- Custom identity servers

**Flow Types:**
- **Authorization Code**: User-facing web apps
- **Client Credentials**: Service-to-service
- **Implicit**: Single-page apps (legacy)
- **Resource Owner Password**: Legacy systems (not recommended)

**JWT Validation Policy:**
```xml
<policies>
  <inbound>
    <validate-jwt header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Unauthorized. Access token is missing or invalid.">
      <openid-config url="https://login.microsoftonline.com/{tenant-id}/v2.0/.well-known/openid-configuration" />
      <required-claims>
        <claim name="aud">
          <value>api://your-api-identifier</value>
        </claim>
        <claim name="roles" match="any">
          <value>API.Read</value>
          <value>API.Write</value>
        </claim>
      </required-claims>
    </validate-jwt>
  </inbound>
</policies>
```

**Entra ID Integration:**
```xml
<validate-jwt header-name="Authorization">
  <openid-config url="https://login.microsoftonline.com/{{tenant-id}}/v2.0/.well-known/openid-configuration" />
  <audiences>
    <audience>{{api-audience}}</audience>
  </audiences>
  <issuers>
    <issuer>https://sts.windows.net/{{tenant-id}}/</issuer>
  </issuers>
  <required-claims>
    <claim name="scp" match="any">
      <value>user_impersonation</value>
    </claim>
  </required-claims>
</validate-jwt>
```

### 3. Client Certificates (Mutual TLS)

Authenticate clients using X.509 certificates for high-security scenarios.

**Use cases:**
- B2B partner integrations
- Service-to-service communication
- High-security requirements
- Legacy system integration

**Certificate Validation Policy:**
```xml
<policies>
  <inbound>
    <choose>
      <when condition="@(context.Request.Certificate == null)">
        <return-response>
          <set-status code="403" reason="Invalid client certificate" />
        </return-response>
      </when>
      <when condition="@(!context.Request.Certificate.Verify())">
        <return-response>
          <set-status code="403" reason="Invalid client certificate" />
        </return-response>
      </when>
    </choose>
    <!-- Validate certificate thumbprint -->
    <choose>
      <when condition="@(context.Request.Certificate.Thumbprint != "EXPECTED_THUMBPRINT")">
        <return-response>
          <set-status code="403" reason="Unauthorized certificate" />
        </return-response>
      </when>
    </choose>
  </inbound>
</policies>
```

**Advanced Certificate Validation:**
```xml
<policies>
  <inbound>
    <choose>
      <!-- Check if certificate is present -->
      <when condition="@(context.Request.Certificate == null)">
        <return-response>
          <set-status code="401" reason="Certificate required" />
        </return-response>
      </when>
      <!-- Validate issuer -->
      <when condition="@(context.Request.Certificate.Issuer != "CN=Contoso CA")">
        <return-response>
          <set-status code="403" reason="Invalid issuer" />
        </return-response>
      </when>
      <!-- Check expiration -->
      <when condition="@(context.Request.Certificate.NotAfter < DateTime.Now)">
        <return-response>
          <set-status code="403" reason="Certificate expired" />
        </return-response>
      </when>
      <!-- Validate against allowed list (stored in Named Value) -->
      <when condition="@(!context.Request.Certificate.Thumbprint.Equals("{{allowed-cert-thumbprint}}", StringComparison.OrdinalIgnoreCase))">
        <return-response>
          <set-status code="403" reason="Certificate not authorized" />
        </return-response>
      </when>
    </choose>
  </inbound>
</policies>
```

### 4. Managed Identity

Azure Managed Identity for authenticating APIM to backend Azure services without credentials.

**Supported Services:**
- Azure Key Vault
- Azure Storage
- Azure SQL
- Azure Functions
- Azure Service Bus
- Azure Event Hubs

**Backend Authentication Example:**
```xml
<policies>
  <inbound>
    <base />
  </inbound>
  <backend>
    <authentication-managed-identity resource="https://storage.azure.com/" />
  </backend>
</policies>
```

**Key Vault Integration:**
```xml
<!-- Named Value configured with Key Vault reference -->
<set-header name="Authorization" exists-action="override">
  <value>Bearer {{backend-api-key}}</value>
</set-header>
```

## Authorization Patterns

### 1. Role-Based Access Control (RBAC)

Validate JWT claims or groups for authorization.

```xml
<policies>
  <inbound>
    <validate-jwt header-name="Authorization">
      <openid-config url="https://login.microsoftonline.com/{{tenant-id}}/v2.0/.well-known/openid-configuration" />
      <required-claims>
        <claim name="roles" match="any">
          <value>Admin</value>
          <value>Editor</value>
        </claim>
      </required-claims>
    </validate-jwt>
  </inbound>
</policies>
```

### 2. Scope-Based Authorization

Validate OAuth scopes for fine-grained access.

```xml
<validate-jwt header-name="Authorization">
  <openid-config url="https://login.microsoftonline.com/{{tenant-id}}/v2.0/.well-known/openid-configuration" />
  <required-claims>
    <claim name="scp" match="all">
      <value>api.read</value>
      <value>api.write</value>
    </claim>
  </required-claims>
</validate-jwt>
```

### 3. Custom Authorization

Call external authorization service for complex logic.

```xml
<policies>
  <inbound>
    <send-request mode="new" response-variable-name="authResponse" timeout="10" ignore-error="false">
      <set-url>https://auth-service.example.com/authorize</set-url>
      <set-method>POST</set-method>
      <set-header name="Content-Type" exists-action="override">
        <value>application/json</value>
      </set-header>
      <set-body>@{
        return new JObject(
          new JProperty("userId", context.Request.Headers.GetValueOrDefault("X-User-Id","")),
          new JProperty("resource", context.Api.Path),
          new JProperty("action", context.Request.Method)
        ).ToString();
      }</set-body>
    </send-request>
    <choose>
      <when condition="@(((IResponse)context.Variables["authResponse"]).StatusCode != 200)">
        <return-response>
          <set-status code="403" reason="Forbidden" />
          <set-body>Access denied</set-body>
        </return-response>
      </when>
    </choose>
  </inbound>
</policies>
```

## TLS and Certificates

### Enforce TLS 1.2+

```xml
<policies>
  <inbound>
    <choose>
      <when condition="@(context.Request.OriginalUrl.Scheme != "https")">
        <return-response>
          <set-status code="403" reason="HTTPS required" />
        </return-response>
      </when>
    </choose>
  </inbound>
</policies>
```

### Backend Certificate Validation

```xml
<policies>
  <backend>
    <base />
  </backend>
  <on-error>
    <choose>
      <when condition="@(context.LastError.Reason == "SSLHandshakeFailed")">
        <return-response>
          <set-status code="502" reason="Backend certificate invalid" />
        </return-response>
      </when>
    </choose>
  </on-error>
</policies>
```

### Custom Domain with Key Vault Certificate

```bicep
resource apim 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  name: 'apim-secure'
  properties: {
    hostnameConfigurations: [
      {
        type: 'Proxy'
        hostName: 'api.contoso.com'
        certificateSource: 'KeyVault'
        keyVaultId: 'https://kv-contoso.vault.azure.net/secrets/api-cert'
        identityClientId: apim.identity.principalId
      }
    ]
  }
  identity: {
    type: 'SystemAssigned'
  }
}
```

## Secrets Management

### Azure Key Vault Integration

**Best Practice**: Never hardcode secrets in policies; use Named Values backed by Key Vault.

**Setup:**

1. **Enable Managed Identity** on APIM
2. **Grant Key Vault access** to APIM identity
3. **Create Named Value** with Key Vault reference
4. **Reference in policies** using `{{named-value}}`

**Named Value Configuration:**
```bash
az apim nv create \
  --resource-group rg-apim \
  --service-name apim-instance \
  --named-value-id backend-api-key \
  --display-name "Backend API Key" \
  --secret true \
  --key-vault "https://kv-contoso.vault.azure.net/secrets/backend-key"
```

**Policy Usage:**
```xml
<set-header name="X-API-Key" exists-action="override">
  <value>{{backend-api-key}}</value>
</set-header>
```

### Connection String Protection

```xml
<!-- BAD: Hardcoded connection string -->
<set-backend-service base-url="https://backend.com?key=secret123" />

<!-- GOOD: Use Named Value from Key Vault -->
<set-backend-service base-url="@($"https://backend.com?key={{backend-connection-key}}")" />
```

## Policy-Based Security

### IP Filtering

```xml
<policies>
  <inbound>
    <!-- Allow specific IP ranges -->
    <ip-filter action="allow">
      <address>13.66.201.169</address>
      <address-range from="192.168.1.1" to="192.168.1.254" />
    </ip-filter>
  </inbound>
</policies>
```

### Rate Limiting and Quotas

```xml
<policies>
  <inbound>
    <!-- Rate limit: 100 calls per 60 seconds -->
    <rate-limit calls="100" renewal-period="60" />
    
    <!-- Quota: 10,000 calls per week -->
    <quota calls="10000" renewal-period="604800" />
    
    <!-- Rate limit by client IP -->
    <rate-limit-by-key calls="10" renewal-period="60" counter-key="@(context.Request.IpAddress)" />
  </inbound>
</policies>
```

### Request Validation

```xml
<policies>
  <inbound>
    <!-- Validate content type -->
    <choose>
      <when condition="@(context.Request.Headers.GetValueOrDefault("Content-Type","").StartsWith("application/json") == false)">
        <return-response>
          <set-status code="415" reason="Unsupported Media Type" />
        </return-response>
      </when>
    </choose>
    
    <!-- Validate request size -->
    <choose>
      <when condition="@(context.Request.Body.As<string>(preserveContent: true).Length > 1048576)">
        <return-response>
          <set-status code="413" reason="Payload Too Large" />
        </return-response>
      </when>
    </choose>
  </inbound>
</policies>
```

### CORS Configuration

```xml
<policies>
  <inbound>
    <cors allow-credentials="true">
      <allowed-origins>
        <origin>https://app.contoso.com</origin>
        <origin>https://admin.contoso.com</origin>
      </allowed-origins>
      <allowed-methods preflight-result-max-age="300">
        <method>GET</method>
        <method>POST</method>
        <method>PUT</method>
        <method>DELETE</method>
      </allowed-methods>
      <allowed-headers>
        <header>Content-Type</header>
        <header>Authorization</header>
      </allowed-headers>
      <expose-headers>
        <header>X-Request-Id</header>
      </expose-headers>
    </cors>
  </inbound>
</policies>
```

### SQL Injection Prevention

```xml
<policies>
  <inbound>
    <set-variable name="query" value="@(context.Request.Url.Query.GetValueOrDefault("query",""))" />
    <choose>
      <when condition="@{
        var query = (string)context.Variables["query"];
        return query.Contains("'") || query.Contains("--") || query.Contains(";");
      }">
        <return-response>
          <set-status code="400" reason="Invalid input" />
        </return-response>
      </when>
    </choose>
  </inbound>
</policies>
```

## Network Security

### Virtual Network Integration

- **External VNet**: Public gateway, private backends
- **Internal VNet**: Fully private, requires App Gateway for public access
- **Private Endpoints**: Private connectivity without VNet injection

See [Networking Guide](networking.md) for details.

### DDoS Protection

- Azure DDoS Protection Standard on VNet
- Rate limiting policies
- Application Gateway WAF
- Azure Front Door with WAF

### Firewall Rules

```xml
<!-- Allow only specific user agents -->
<policies>
  <inbound>
    <choose>
      <when condition="@{
        var userAgent = context.Request.Headers.GetValueOrDefault("User-Agent","");
        return !userAgent.StartsWith("MyApp/");
      }">
        <return-response>
          <set-status code="403" reason="Forbidden" />
        </return-response>
      </when>
    </choose>
  </inbound>
</policies>
```

## Compliance and Auditing

### Diagnostic Logging

**Enable comprehensive logging:**

```bicep
resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'apim-diagnostics'
  scope: apim
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'GatewayLogs'
        enabled: true
      }
      {
        category: 'WebSocketConnectionLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}
```

### PII Redaction

```xml
<policies>
  <inbound>
    <!-- Remove sensitive headers from logs -->
    <set-header name="Authorization" exists-action="delete" />
    <set-header name="X-API-Key" exists-action="delete" />
  </inbound>
</policies>
```

### Audit Trail

Log all API calls to Log Analytics:

```kusto
ApiManagementGatewayLogs
| where TimeGenerated > ago(24h)
| where ResponseCode >= 400
| project TimeGenerated, ApiId, OperationId, Method, Url, ResponseCode, ClientIp
| order by TimeGenerated desc
```

### Compliance Standards

APIM supports compliance with:
- SOC 1, 2, 3
- ISO 27001, 27018, 27017
- PCI DSS Level 1
- HIPAA
- GDPR
- FedRAMP (Government cloud)

## Security Checklist

### Production Readiness

- [ ] TLS 1.2+ enforced
- [ ] Subscription keys required or JWT validation implemented
- [ ] Secrets stored in Azure Key Vault
- [ ] Managed Identity enabled for Azure service connections
- [ ] Rate limiting and quotas configured
- [ ] Diagnostic logging enabled
- [ ] Network security configured (NSG, Private Endpoints)
- [ ] Custom domains with valid certificates
- [ ] CORS properly configured
- [ ] Input validation policies applied
- [ ] IP filtering for sensitive operations
- [ ] Backend certificate validation enabled
- [ ] Regular security audits scheduled
- [ ] Incident response plan documented

## Security Monitoring

### Key Metrics to Monitor

- Failed authentication attempts
- Rate limit violations
- 401/403 response codes
- Certificate expiration dates
- Unusual traffic patterns
- Backend connection errors

### Alert Configuration

```kusto
// High rate of 401 responses (authentication failures)
ApiManagementGatewayLogs
| where TimeGenerated > ago(5m)
| where ResponseCode == 401
| summarize Count=count() by bin(TimeGenerated, 1m)
| where Count > 100

// Certificate expiring soon
ApiManagementGatewayLogs
| where TimeGenerated > ago(1d)
| where CertificateExpiryDate < now() + 30d
| distinct CertificateName, CertificateExpiryDate
```

## Best Practices Summary

1. **Use JWT validation** for user-facing APIs
2. **Store secrets in Key Vault**, reference via Named Values
3. **Enable Managed Identity** for Azure service connections
4. **Implement rate limiting** to prevent abuse
5. **Use IP filtering** for sensitive operations
6. **Enable diagnostic logging** for audit trails
7. **Validate inputs** to prevent injection attacks
8. **Use TLS 1.2+** exclusively
9. **Rotate secrets regularly** (subscription keys, certificates)
10. **Monitor security metrics** and set up alerts
11. **Apply principle of least privilege** in policies
12. **Test security controls** regularly
13. **Document security architecture** and policies
14. **Keep dependencies updated** (certificates, SDKs)
15. **Implement defense in depth** across all layers

## Additional Resources

- [APIM Security Best Practices](https://learn.microsoft.com/azure/api-management/security-controls-policy)
- [OAuth 2.0 in APIM](https://learn.microsoft.com/azure/api-management/api-management-howto-protect-backend-with-aad)
- [Certificate Authentication](https://learn.microsoft.com/azure/api-management/api-management-howto-mutual-certificates)
- [Key Vault Integration](https://learn.microsoft.com/azure/api-management/api-management-howto-properties)
- [Security Baseline for APIM](https://learn.microsoft.com/security/benchmark/azure/baselines/api-management-security-baseline)

## Next Steps

- [Networking Guide](networking.md) - Secure network configuration
- [Observability](observability.md) - Monitor security events
- [Troubleshooting](troubleshooting.md) - Debug security issues

---

**Security is a journey, not a destination.** Continuously review and improve your security posture!
