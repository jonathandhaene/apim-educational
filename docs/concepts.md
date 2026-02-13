# Azure API Management Core Concepts

This guide introduces the fundamental concepts and architecture of Azure API Management (APIM).

## Table of Contents
- [What is Azure API Management?](#what-is-azure-api-management)
- [Core Components](#core-components)
- [API Gateway Patterns](#api-gateway-patterns)
- [Key Features](#key-features)
- [Architecture Overview](#architecture-overview)
- [Common Use Cases](#common-use-cases)

## What is Azure API Management?

Azure API Management is a fully managed service that enables organizations to:
- **Publish APIs** to external, partner, and internal developers
- **Secure and protect** APIs with policies and authentication
- **Monitor and analyze** API usage and performance
- **Monetize APIs** through subscription models
- **Transform and route** requests to backend services

### Value Proposition

- **Developer Portal**: Self-service API discovery and onboarding
- **Gateway**: Centralized request/response processing and policy enforcement
- **Management Plane**: API configuration, monitoring, and analytics
- **Policy Engine**: Declarative transformation, security, and throttling

## Core Components

### 1. API Gateway

The gateway is the runtime component that:
- Accepts API calls and routes them to backends
- Verifies API keys, JWT tokens, and certificates
- Enforces quotas and rate limits
- Caches responses to improve performance
- Logs requests for monitoring and analytics
- Transforms requests and responses on the fly

**Deployment Options:**
- **Managed Gateway**: Hosted in Azure (all tiers)
- **Self-hosted Gateway**: Container-based, runs on-premises or other clouds
- **Consumption Gateway**: Serverless, auto-scales to zero

### 2. Management API

RESTful API for:
- Creating and managing APIs
- Configuring policies
- Managing users and subscriptions
- Retrieving analytics data

Access via:
- Azure Portal
- Azure CLI
- PowerShell
- ARM/Bicep/Terraform
- REST API directly

### 3. Developer Portal

Customizable website for developers to:
- Browse API catalog and documentation
- Try APIs interactively
- Subscribe to products and obtain keys
- View usage analytics
- Read tutorials and guides

**Customization:**
- Built-in visual editor
- Custom HTML/CSS/JavaScript
- Self-hosted option available

### 4. Azure Portal

Web interface for administrators to:
- Configure APIM instance
- Design and manage APIs
- Create policies
- Monitor health and metrics
- Manage users and groups

## API Gateway Patterns

### 1. API Aggregation

Combine multiple backend calls into a single API endpoint:
```xml
<policies>
  <inbound>
    <send-request mode="new" response-variable-name="userdata">
      <set-url>https://user-service.example.com/users/{{userId}}</set-url>
    </send-request>
    <send-request mode="new" response-variable-name="orders">
      <set-url>https://order-service.example.com/orders?user={{userId}}</set-url>
    </send-request>
  </inbound>
  <outbound>
    <!-- Combine responses -->
  </outbound>
</policies>
```

### 2. Backend for Frontend (BFF)

Create specialized APIs for different client types:
- Mobile app: lightweight, optimized payloads
- Web app: richer data structures
- Partner integrations: versioned, stable contracts

### 3. Rate Limiting and Throttling

Protect backends from overload:
```xml
<rate-limit calls="100" renewal-period="60" />
<quota calls="10000" renewal-period="604800" />
```

### 4. Circuit Breaker

Fail fast when backend is unhealthy:
```xml
<retry condition="@(context.Response.StatusCode == 500)" count="3" interval="1" />
```

### 5. Request/Response Transformation

Adapt protocols and formats:
- XML ↔ JSON conversion
- SOAP to REST wrapping
- Header manipulation
- Payload restructuring

## Key Features

### Security

- **Subscription Keys**: Simple API key authentication
- **JWT Validation**: OAuth 2.0 / OpenID Connect token validation
- **Client Certificates**: Mutual TLS authentication
- **IP Filtering**: Whitelist/blacklist IP ranges
- **OAuth 2.0 Authorization**: Built-in authorization server
- **Managed Identity**: Connect to Azure services without credentials

### Traffic Management

- **Rate Limiting**: Calls per time period per subscription/key/IP
- **Quota**: Long-term usage caps
- **Throttling**: Concurrent request limits
- **Caching**: Response caching with TTL

### Monitoring & Analytics

- **Application Insights**: Detailed telemetry and traces
- **Log Analytics**: Centralized logging and queries
- **Metrics**: Request count, latency, error rates
- **Alerts**: Proactive notifications on thresholds

### Developer Experience

- **OpenAPI (Swagger)**: Import/export API definitions
- **GraphQL**: Query and mutation support
- **WebSocket**: Bidirectional communication
- **Interactive Console**: Test APIs from portal

### Transformation

- **Content Negotiation**: Accept/Content-Type handling
- **JSON/XML Conversion**: Automatic format transformation
- **XSLT**: Advanced XML transformations
- **Liquid Templates**: Flexible content transformation

## Architecture Overview

### High-Level Architecture

```
┌─────────────┐
│   Clients   │ (Web, Mobile, IoT, Partners)
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────────┐
│     Azure API Management Gateway        │
│  ┌────────────────────────────────────┐ │
│  │  Policy Pipeline (Inbound)         │ │
│  │  - Authentication                  │ │
│  │  - Rate Limiting                   │ │
│  │  - Transformation                  │ │
│  └────────────────────────────────────┘ │
└─────────────┬───────────────────────────┘
              │
              ▼
      ┌───────────────┐
      │   Backend     │
      │   Services    │
      │ ─────────────│
      │ • Azure       │
      │   Functions   │
      │ • App Service │
      │ • AKS         │
      │ • Logic Apps  │
      │ • External    │
      │   APIs        │
      └───────────────┘
```

### Request Flow

1. **Client** sends request to APIM gateway URL
2. **Gateway** validates subscription key or JWT token
3. **Inbound policies** execute (authentication, rate limit, transform)
4. **Backend** request is forwarded to configured backend service
5. **Backend** processes and returns response
6. **Outbound policies** execute (transform, cache, filter)
7. **Response** returned to client
8. **Analytics** data logged to Application Insights

### Data Plane vs. Control Plane

**Data Plane (Gateway):**
- Processes API requests in real-time
- Enforces policies
- Routes to backends
- Logs telemetry

**Control Plane (Management API):**
- Configures APIs and policies
- Manages subscriptions
- Provisions resources
- Generates reports

## Common Use Cases

### 1. Microservices Facade

Expose multiple microservices through a unified API gateway:
- Single entry point for clients
- Centralized authentication and authorization
- Consistent error handling and logging
- Version management across services

### 2. Legacy Modernization

Modernize legacy systems without rewriting:
- Wrap SOAP services with RESTful APIs
- Add OAuth to basic auth backends
- Implement rate limiting on legacy systems
- Transform XML to JSON

### 3. API Monetization

Create tiered API products:
- Free tier: Limited calls, public data
- Basic tier: Higher limits, more endpoints
- Premium tier: Unlimited, SLA, dedicated support

### 4. Multi-region Deployment

Deploy globally with low latency:
- Premium tier: Built-in multi-region support
- Front Door: Route to nearest region
- Traffic Manager: Failover and load balancing

### 5. Third-Party API Integration

Aggregate and expose third-party APIs:
- Cache responses to reduce costs
- Add authentication layer
- Normalize response formats
- Monitor usage and performance

### 6. Internal API Management

Govern internal APIs:
- Centralized catalog and discovery
- Consistent policies across teams
- Usage tracking and chargeback
- API lifecycle management

### 7. IoT Device Management

Secure and scale IoT communications:
- Device authentication with certificates
- Protocol translation (MQTT, AMQP)
- Rate limiting per device
- Firmware update APIs

### 8. Partner Integration

Provide APIs to partners:
- Self-service developer portal
- Subscription-based access control
- Usage quotas and billing
- SLA enforcement

## Best Practices

### Design

1. **Use Products** to group related APIs
2. **Version APIs** with path or header-based versioning
3. **Apply policies** at appropriate scopes (global, product, API, operation)
4. **Design for idempotency** where possible
5. **Document thoroughly** in OpenAPI specifications

### Security

1. **Always use HTTPS** for production
2. **Implement JWT validation** for user-facing APIs
3. **Use Managed Identity** for Azure service connections
4. **Store secrets** in Key Vault, reference via Named Values
5. **Apply IP filtering** for sensitive operations
6. **Enable diagnostic logging** for security auditing

### Performance

1. **Cache responses** where appropriate with TTL
2. **Use compression** to reduce bandwidth
3. **Implement retry** with exponential backoff
4. **Monitor backend latency** and optimize slow endpoints
5. **Consider response pagination** for large datasets

### Operations

1. **Use Infrastructure as Code** (Bicep/Terraform)
2. **Implement CI/CD** for API deployments
3. **Monitor with Application Insights**
4. **Set up alerts** for errors and latency
5. **Plan for disaster recovery** with multi-region or backups

## Learning Resources

- [Official APIM Documentation](https://learn.microsoft.com/azure/api-management/)
- [Policy Reference](https://learn.microsoft.com/azure/api-management/api-management-policies)
- [Policy Expressions](https://learn.microsoft.com/azure/api-management/api-management-policy-expressions)
- [REST API Reference](https://learn.microsoft.com/rest/api/apimanagement/)
- [Architecture Patterns](https://learn.microsoft.com/azure/architecture/reference-architectures/apis/)

## Next Steps

- [Networking Guide](networking.md) - Configure VNet integration and private endpoints
- [Security Guide](security.md) - Implement authentication and authorization
- [Tiers and SKUs](tiers-and-skus.md) - Choose the right tier for your needs
- [Observability](observability.md) - Set up monitoring and diagnostics

---

**Feedback?** Open an issue or contribute improvements via pull request!
