# Azure Front Door + API Management Integration

Guide for integrating Azure Front Door with Azure API Management for global distribution, caching, and WAF capabilities.

## Table of Contents
- [Why Front Door + APIM?](#why-front-door--apim)
- [Architecture Patterns](#architecture-patterns)
- [Setup and Configuration](#setup-and-configuration)
- [Performance Optimization](#performance-optimization)
- [Security Configuration](#security-configuration)

## Why Front Door + APIM?

### Azure Front Door Capabilities

- **Global Load Balancing**: Route to nearest APIM region
- **CDN**: Cache static content and API responses at edge
- **WAF**: Web Application Firewall for DDoS and OWASP Top 10 protection
- **SSL Offloading**: Terminate TLS at edge
- **Path-based Routing**: Route different paths to different backends
- **Fast Failover**: Automatic failover to healthy regions

### Use Cases

1. **Global APIs**: Low latency for users worldwide
2. **High Traffic**: Offload caching to CDN
3. **Security**: WAF protection before traffic reaches APIM
4. **Multi-Backend**: Route to different APIM instances or other backends
5. **Legacy Migration**: Gradually migrate from old to new APIs

### When to Use This Pattern

✅ **Use Front Door + APIM when:**
- Global user base requiring low latency
- High traffic with cacheable responses
- Need WAF protection
- Multi-region APIM deployment
- Require advanced routing rules

❌ **Don't use if:**
- Single-region with low traffic (added complexity)
- All responses are dynamic/uncacheable
- Budget constrained (Front Door adds cost)
- Simple requirements (APIM alone sufficient)

## Architecture Patterns

### Pattern 1: Global Distribution (Multi-Region APIM)

```
                    Azure Front Door
                    (Global Endpoint)
                           |
        ┌──────────────────┼──────────────────┐
        │                  │                  │
   [US-East APIM]    [Europe APIM]    [Asia APIM]
        │                  │                  │
    [Backends]        [Backends]        [Backends]
```

**Benefits:**
- Lowest latency globally
- Regional failover
- Compliance (data residency)

**Configuration:**
- APIM Premium tier (multi-region)
- Front Door Priority-based or Performance-based routing
- Health probes per region

### Pattern 2: Single Region with WAF

```
Internet → Front Door (WAF) → APIM (Internal VNet) → Backends
```

**Benefits:**
- WAF protection
- APIM in private network
- Single point for security policies

**Configuration:**
- APIM in Internal VNet mode
- Front Door with WAF Premium (advanced rules)
- Private Link from Front Door to APIM

### Pattern 3: Hybrid Multi-Backend

```
                Front Door
                    |
      ┌─────────────┼─────────────┐
      │             │             │
   [APIM]    [App Service]   [Storage]
   /api/*      /web/*         /static/*
```

**Benefits:**
- Route different paths to appropriate backends
- Single domain for multiple services
- Consolidated monitoring

### Pattern 4: Caching Layer

```
User → Front Door (Cache) → APIM → Backend API
```

**Benefits:**
- Reduced APIM and backend load
- Faster responses for cacheable content
- Lower costs (fewer APIM/backend requests)

## Setup and Configuration

### Prerequisites

- Azure Front Door Standard or Premium
- Azure API Management (any tier, Premium recommended for multi-region)
- Custom domain and certificate

### Step 1: Create Front Door

**Bicep:**
```bicep
resource frontDoor 'Microsoft.Cdn/profiles@2023-05-01' = {
  name: 'fd-api-global'
  location: 'global'
  sku: {
    name: 'Premium_AzureFrontDoor'  // Use Premium for WAF, Private Link
  }
}

resource endpoint 'Microsoft.Cdn/profiles/afdEndpoints@2023-05-01' = {
  parent: frontDoor
  name: 'api-global'
  location: 'global'
  properties: {
    enabledState: 'Enabled'
  }
}
```

### Step 2: Configure Origin Group

**Backend: APIM Gateway**

```bicep
resource originGroup 'Microsoft.Cdn/profiles/originGroups@2023-05-01' = {
  parent: frontDoor
  name: 'apim-origins'
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: 50
    }
    healthProbeSettings: {
      probePath: '/status-0123456789abcdef'
      probeRequestType: 'GET'
      probeProtocol: 'Https'
      probeIntervalInSeconds: 30
    }
  }
}

// Primary region (US East)
resource originUsEast 'Microsoft.Cdn/profiles/originGroups/origins@2023-05-01' = {
  parent: originGroup
  name: 'apim-useast'
  properties: {
    hostName: 'apim-useast.azure-api.net'
    httpPort: 80
    httpsPort: 443
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
  }
}

// Secondary region (Europe)
resource originEurope 'Microsoft.Cdn/profiles/originGroups/origins@2023-05-01' = {
  parent: originGroup
  name: 'apim-europe'
  properties: {
    hostName: 'apim-europe.azure-api.net'
    httpPort: 80
    httpsPort: 443
    priority: 2
    weight: 1000
    enabledState: 'Enabled'
  }
}
```

### Step 3: Configure Route

```bicep
resource route 'Microsoft.Cdn/profiles/afdEndpoints/routes@2023-05-01' = {
  parent: endpoint
  name: 'api-route'
  properties: {
    originGroup: {
      id: originGroup.id
    }
    supportedProtocols: ['Https']
    patternsToMatch: ['/api/*']
    forwardingProtocol: 'HttpsOnly'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
    cacheConfiguration: {
      queryStringCachingBehavior: 'IgnoreQueryString'
      compressionSettings: {
        contentTypesToCompress: [
          'application/json'
          'application/xml'
          'text/plain'
        ]
        isCompressionEnabled: true
      }
    }
  }
}
```

### Step 4: Custom Domain

```bicep
resource customDomain 'Microsoft.Cdn/profiles/customDomains@2023-05-01' = {
  parent: frontDoor
  name: 'api-contoso-com'
  properties: {
    hostName: 'api.contoso.com'
    tlsSettings: {
      certificateType: 'ManagedCertificate'
      minimumTlsVersion: 'TLS12'
    }
  }
}

// DNS: CNAME api.contoso.com → api-global-xxxxxx.azurefd.net
```

### Step 5: Configure APIM

**Restrict Access to Front Door Only:**

```xml
<policies>
  <inbound>
    <!-- Verify request comes from Front Door -->
    <check-header name="X-Azure-FDID" failed-check-httpcode="403" failed-check-error-message="Access denied" ignore-case="true">
      <value>YOUR-FRONT-DOOR-ID</value>
    </check-header>
    
    <!-- Or use IP restrictions (Front Door IP ranges) -->
    <ip-filter action="allow">
      <address-range from="147.243.0.0" to="147.243.255.255" />
      <!-- Add all Front Door IP ranges -->
    </ip-filter>
  </inbound>
</policies>
```

**Preserve Client IP:**
```xml
<policies>
  <inbound>
    <!-- Front Door adds X-Forwarded-For -->
    <set-header name="X-Original-Client-IP" exists-action="override">
      <value>@(context.Request.Headers.GetValueOrDefault("X-Forwarded-For", "").Split(',')[0].Trim())</value>
    </set-header>
  </inbound>
</policies>
```

## Performance Optimization

### Caching Strategy

**Cache at Front Door (Edge):**
```bicep
cacheConfiguration: {
  queryStringCachingBehavior: 'UseQueryString'  // or IgnoreQueryString
  cacheDuration: 'PT1H'  // 1 hour
}
```

**Cache Rules:**
- **GET requests only**: Only GET and HEAD are cached
- **Cache-Control headers**: Respect from backend
- **Query strings**: Decide based on API semantics
- **Vary by header**: Useful for versioning (`Accept-Version`)

**APIM Policy to Set Cache Headers:**
```xml
<policies>
  <outbound>
    <choose>
      <when condition="@(context.Request.Method == "GET" && context.Response.StatusCode == 200)">
        <set-header name="Cache-Control" exists-action="override">
          <value>public, max-age=3600</value>
        </set-header>
      </when>
      <otherwise>
        <set-header name="Cache-Control" exists-action="override">
          <value>no-cache</value>
        </set-header>
      </otherwise>
    </choose>
  </outbound>
</policies>
```

### Compression

**Enable at Front Door:**
- Automatic GZIP/Brotli compression
- Reduces bandwidth by 70-90% for JSON/XML

**Content types to compress:**
```bicep
compressionSettings: {
  contentTypesToCompress: [
    'application/json'
    'application/xml'
    'text/html'
    'text/plain'
    'text/css'
    'application/javascript'
  ]
  isCompressionEnabled: true
}
```

### Connection Pooling

- Front Door maintains persistent connections to origins
- Reduces SSL handshake overhead
- Improves backend performance

## Security Configuration

### WAF (Premium Tier Required)

**Enable WAF:**
```bicep
resource wafPolicy 'Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2022-05-01' = {
  name: 'waf-api-policy'
  location: 'global'
  sku: {
    name: 'Premium_AzureFrontDoor'
  }
  properties: {
    policySettings: {
      enabledState: 'Enabled'
      mode: 'Prevention'  // or 'Detection' for testing
      requestBodyCheck: 'Enabled'
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'Microsoft_DefaultRuleSet'
          ruleSetVersion: '2.1'
          ruleGroupOverrides: []
        }
        {
          ruleSetType: 'Microsoft_BotManagerRuleSet'
          ruleSetVersion: '1.0'
        }
      ]
    }
    customRules: {
      rules: [
        {
          name: 'RateLimitRule'
          priority: 100
          enabledState: 'Enabled'
          ruleType: 'RateLimitRule'
          rateLimitThreshold: 100
          rateLimitDurationInMinutes: 1
          matchConditions: [
            {
              matchVariable: 'RequestUri'
              operator: 'Contains'
              matchValue: ['/api/']
            }
          ]
          action: 'Block'
        }
        {
          name: 'GeoBlockRule'
          priority: 200
          enabledState: 'Enabled'
          ruleType: 'MatchRule'
          matchConditions: [
            {
              matchVariable: 'RemoteAddr'
              operator: 'GeoMatch'
              matchValue: ['CN', 'RU']  // Block specific countries
              negateCondition: false
            }
          ]
          action: 'Block'
        }
      ]
    }
  }
}

// Associate WAF with endpoint
resource securityPolicy 'Microsoft.Cdn/profiles/securityPolicies@2023-05-01' = {
  parent: frontDoor
  name: 'api-security-policy'
  properties: {
    parameters: {
      type: 'WebApplicationFirewall'
      wafPolicy: {
        id: wafPolicy.id
      }
      associations: [
        {
          domains: [
            { id: endpoint.id }
          ]
          patternsToMatch: ['/*']
        }
      ]
    }
  }
}
```

### Private Link (Premium Tier)

**Connect Front Door to Internal APIM:**
```bicep
resource privateEndpoint 'Microsoft.Cdn/profiles/originGroups/origins@2023-05-01' = {
  parent: originGroup
  name: 'apim-private'
  properties: {
    hostName: 'apim-internal.azure-api.net'
    httpPort: 80
    httpsPort: 443
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
    sharedPrivateLinkResource: {
      privateLink: {
        id: apim.id
      }
      privateLinkLocation: location
      requestMessage: 'Front Door Private Link to APIM'
    }
  }
}
```

## Monitoring and Diagnostics

### Front Door Logs

```bicep
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'fd-diagnostics'
  scope: frontDoor
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'FrontDoorAccessLog'
        enabled: true
      }
      {
        category: 'FrontDoorHealthProbeLog'
        enabled: true
      }
      {
        category: 'FrontDoorWebApplicationFirewallLog'
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

### Key Metrics

- **Request Count**: Total requests to Front Door
- **Request Size/Response Size**: Bandwidth usage
- **Cache Hit Ratio**: Effectiveness of caching
- **Backend Health**: Percentage of healthy origins
- **WAF Blocks**: Requests blocked by WAF

### Log Queries

**Cache Hit Ratio:**
```kusto
AzureDiagnostics
| where Category == "FrontDoorAccessLog"
| summarize Total = count(), Hits = countif(cacheStatus_s == "HIT") by bin(TimeGenerated, 1h)
| extend HitRatio = todouble(Hits) / Total * 100
| render timechart
```

**WAF Blocks:**
```kusto
AzureDiagnostics
| where Category == "FrontDoorWebApplicationFirewallLog"
| where action_s == "Block"
| summarize Count = count() by ruleName_s
| order by Count desc
```

## Best Practices

1. **Use Premium Tier**: For WAF and Private Link
2. **Health Probes**: Configure appropriate probe path and frequency
3. **Caching**: Cache GET requests with appropriate TTL
4. **Compression**: Enable for all text-based content
5. **WAF Mode**: Start in Detection, move to Prevention after tuning
6. **Custom Domains**: Use managed certificates for simplicity
7. **Monitor Logs**: Set up alerts for health probes and WAF blocks
8. **Failover Testing**: Regularly test regional failover
9. **Cost Optimization**: Monitor bandwidth and request counts
10. **Security**: Restrict APIM to accept only Front Door traffic

## Cost Considerations

### Front Door Pricing (Approximate)

- **Base**: ~$35/month
- **Bandwidth**: ~$0.08/GB outbound
- **Requests**: ~$0.0125 per 10K requests
- **WAF Premium**: Additional ~$325/month

**Example Monthly Cost:**
- 100M requests: 100M / 10K × $0.0125 = $125
- 1TB bandwidth: 1000GB × $0.08 = $80
- Premium + WAF: $35 + $325 = $360
- **Total**: ~$565/month

**Cost Optimization:**
- Use caching to reduce origin requests
- Compression reduces bandwidth costs
- Monitor and optimize cache hit ratio
- Consider Standard tier if WAF not needed

## Additional Resources

- [Front Door Documentation](https://learn.microsoft.com/azure/frontdoor/)
- [APIM + Front Door Reference Architecture](https://learn.microsoft.com/azure/architecture/reference-architectures/apis/protect-apis)
- [WAF Best Practices](https://learn.microsoft.com/azure/web-application-firewall/afds/waf-front-door-best-practices)

## Next Steps

- [Networking Guide](networking.md) - Configure internal APIM for Front Door
- [Security Guide](security.md) - Additional security hardening
- [Observability](observability.md) - Monitor Front Door + APIM

---

**Global Scale** requires careful architecture. Front Door + APIM provides enterprise-grade foundation.
