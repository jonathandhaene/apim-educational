# Azure API Management Tiers and SKUs

This guide helps you choose the right Azure API Management tier for your needs, comparing features, limits, and costs.

## Table of Contents
- [Tier Overview](#tier-overview)
- [Feature Comparison](#feature-comparison)
- [Capacity and Scale](#capacity-and-scale)
- [Pricing Comparison](#pricing-comparison)
- [Choosing the Right Tier](#choosing-the-right-tier)
- [Migration Between Tiers](#migration-between-tiers)

## Tier Overview

Azure API Management offers five pricing tiers, each designed for different scenarios:

| Tier | Best For | Starting Price* |
|------|----------|----------------|
| **Consumption** | Serverless, event-driven workloads | Pay-per-execution |
| **Developer** | Development and testing | ~$50/month |
| **Basic** | Production workloads (small) | ~$150/month |
| **Standard** | Production workloads (medium) | ~$750/month |
| **Premium** | Enterprise production workloads | ~$3,000/month |

*Prices are approximate and vary by region. Check [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) for exact costs.

### Consumption Tier

**Serverless API Management** - Pay only for what you use.

**Key Characteristics:**
- **Billing**: Per million API calls + gateway hours
- **Scale**: Automatic, scales to zero when idle
- **Cold Start**: ~10-15 seconds when scaling from zero
- **SLA**: None (best-effort)
- **Limits**: 1,000 requests/second per region

**Use Cases:**
- Development and testing
- Event-driven APIs with variable traffic
- Cost-sensitive workloads
- Prototyping and POCs

**Limitations:**
- No SLA
- No VNet injection (Private Endpoints supported)
- Limited policy support (no caching, no custom domains initially)
- No multi-region deployment
- No self-hosted gateway

**Pros:**
- ✅ Lowest cost for low-traffic scenarios
- ✅ No management overhead
- ✅ Automatic scaling
- ✅ Fast provisioning (~5 minutes)

**Cons:**
- ❌ Cold start latency
- ❌ No SLA
- ❌ Feature limitations

### Developer Tier

**Non-production tier** for development, testing, and evaluation.

**Key Characteristics:**
- **Capacity**: 1 unit (not scalable)
- **SLA**: None
- **Features**: Full feature set (except multi-region)
- **Custom domains**: Supported

**Use Cases:**
- Development environments
- Testing and QA
- Learning and experimentation
- Internal tools (non-critical)

**Limitations:**
- No SLA
- No scaling (fixed 1 unit)
- Single region only
- Not suitable for production

**Pros:**
- ✅ All features available (except scale and multi-region)
- ✅ VNet injection supported
- ✅ Self-hosted gateway supported
- ✅ Cost-effective for non-production

**Cons:**
- ❌ No SLA
- ❌ Cannot scale
- ❌ Single region

### Basic Tier

**Entry-level production tier** with SLA.

**Key Characteristics:**
- **Capacity**: 1-2 units
- **SLA**: 99.95%
- **Features**: Most production features
- **Custom domains**: Supported

**Use Cases:**
- Small production workloads
- Internal APIs with moderate traffic
- Startups and small businesses
- Non-critical production services

**Limitations:**
- No multi-region
- No VNet injection
- Limited scale (max 2 units)
- No availability zones

**Pros:**
- ✅ SLA included
- ✅ Scalable (2 units max)
- ✅ Production-ready features
- ✅ Lower cost than Standard

**Cons:**
- ❌ No VNet injection
- ❌ Limited scale
- ❌ Single region only

### Standard Tier

**Mid-tier production** with scalability and SLA.

**Key Characteristics:**
- **Capacity**: 1-4 units
- **SLA**: 99.95%
- **Features**: Full feature set (no multi-region)
- **Custom domains**: Supported

**Use Cases:**
- Production APIs with moderate-high traffic
- Internal and external APIs
- APIs requiring scalability
- Standard enterprise workloads

**Limitations:**
- No multi-region deployment
- No availability zones
- Limited scale (max 4 units)

**Pros:**
- ✅ SLA included
- ✅ Scalable (4 units max)
- ✅ Full feature set
- ✅ VNet injection supported

**Cons:**
- ❌ No multi-region
- ❌ Higher cost than Basic

### Premium Tier

**Enterprise-grade** with multi-region, high availability, and advanced features.

**Key Characteristics:**
- **Capacity**: 1-12+ units per region
- **SLA**: 99.99% (multi-region), 99.95% (single region)
- **Features**: All features
- **Multi-region**: Yes
- **Availability Zones**: Yes

**Use Cases:**
- Mission-critical production APIs
- Global APIs requiring low latency
- High-traffic workloads (millions of requests/day)
- Disaster recovery requirements
- Compliance and security requirements

**Limitations:**
- Higher cost (but justified for enterprise needs)

**Pros:**
- ✅ Multi-region deployment
- ✅ Availability zones for HA
- ✅ Highest scale (12+ units per region)
- ✅ Best SLA (99.99%)
- ✅ All features included

**Cons:**
- ❌ Highest cost

## Feature Comparison

| Feature | Consumption | Developer | Basic | Standard | Premium |
|---------|-------------|-----------|-------|----------|---------|
| **SLA** | None | None | 99.95% | 99.95% | 99.99%* |
| **Max Scale** | Auto | 1 unit | 2 units | 4 units | 12+ units/region |
| **Max Requests/sec** | 1,000 | 500 | 1,000 | 2,500 | 4,000+/unit |
| **Custom Domains** | Limited | ✅ | ✅ | ✅ | ✅ |
| **VNet Injection** | ❌ | ✅ | ❌ | ✅ | ✅ |
| **Private Endpoints** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Multi-region** | ❌ | ❌ | ❌ | ❌ | ✅ |
| **Availability Zones** | ❌ | ❌ | ❌ | ❌ | ✅ |
| **Self-hosted Gateway** | ❌ | ✅ | ✅ | ✅ | ✅ |
| **Built-in Cache** | ❌ | ✅ | ✅ | ✅ | ✅ |
| **External Cache (Redis)** | ❌ | ✅ | ✅ | ✅ | ✅ |
| **Developer Portal** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **OAuth 2.0 / JWT** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Client Certificates** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Managed Identity** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Backup/Restore** | ❌ | ❌ | ✅ | ✅ | ✅ |
| **Git Configuration** | ❌ | ✅ | ✅ | ✅ | ✅ |

*99.99% SLA with multi-region deployment

## Capacity and Scale

### Unit Capacity

Each APIM unit provides approximate capacity:

| Tier | Requests/sec per Unit | Max Throughput (single unit) |
|------|----------------------|------------------------------|
| Developer | 500 | ~43M requests/day |
| Basic | 500 | ~43M requests/day |
| Standard | 625 | ~54M requests/day |
| Premium | 1,000 | ~86M requests/day |

**Note**: Actual capacity depends on:
- Request/response size
- Policy complexity
- Backend latency
- Connection reuse
- Number of concurrent requests

### Scaling Guidelines

**When to Scale Up:**
- Sustained CPU > 70%
- Request latency increasing
- Capacity metric approaching 100%
- Need more features (e.g., VNet, multi-region)

**When to Scale Out:**
- Need more throughput within same tier
- Traffic growth
- Regional expansion (Premium only)

**Auto-scale:**
- Not available in APIM (manual scale only)
- Consider Consumption tier for auto-scaling scenarios
- Monitor metrics and scale proactively

## Pricing Comparison

### Cost Breakdown (Approximate - USD, East US 2024)

| Tier | Monthly Base | Per Unit/Month | Additional Costs |
|------|--------------|----------------|------------------|
| **Consumption** | $0 | Pay per use | $3.50 per million calls + $0.14/gateway hour |
| **Developer** | $50 | N/A (fixed 1 unit) | None |
| **Basic** | $150 | $150 | None |
| **Standard** | $750 | $750 | None |
| **Premium** | $3,000 | $3,000 | Multi-region: +$3,000 per additional region |

### Cost Examples

**Scenario 1: Development/Testing**
- **Best Tier**: Developer
- **Monthly Cost**: ~$50
- **Rationale**: Full features, no SLA needed for dev

**Scenario 2: Startup with 10M requests/month**
- **Consumption**: $0 + (10 × $3.50) + gateway hours ≈ $35-50/month
- **Basic**: $150/month (1 unit)
- **Best Choice**: Consumption (if traffic is intermittent), Basic (if consistent traffic)

**Scenario 3: Enterprise with 500M requests/month**
- **Standard (4 units)**: 4 × $750 = $3,000/month
- **Premium (2 units)**: 2 × $3,000 = $6,000/month
- **Best Choice**: Standard (if single region sufficient), Premium (if need multi-region or higher SLA)

**Scenario 4: Global enterprise with multi-region**
- **Premium (2 regions, 2 units each)**: 2 regions × 2 units × $3,000 = $12,000/month
- **Benefits**: 99.99% SLA, low latency globally, disaster recovery

### Hidden Costs to Consider

1. **Bandwidth**: Outbound data transfer charges
2. **Application Insights**: Log storage and analytics
3. **Key Vault**: Secret storage and operations
4. **VNet**: IP addresses and VNet peering
5. **Custom Domain Certificates**: Certificate management
6. **Support**: Azure support plans (optional)

### Cost Optimization Tips

1. **Start Small**: Begin with Developer or Consumption, scale as needed
2. **Right-size**: Don't over-provision capacity
3. **Use Consumption for Spiky Workloads**: Avoid paying for idle capacity
4. **Clean Up Dev Instances**: Delete unused non-production instances
5. **Monitor Usage**: Use Azure Cost Management to track spending
6. **Reserved Instances**: Not available for APIM; consider 1-year/3-year commits for discounts
7. **Optimize Policies**: Reduce policy complexity to improve performance and capacity
8. **Cache Responses**: Reduce backend calls and improve response time
9. **Delete Old Revisions**: Reduce storage costs

## Choosing the Right Tier

### Decision Tree

```
START
├─ Production workload?
│  ├─ NO → Developer Tier ($50/mo)
│  └─ YES → Need SLA?
│     ├─ NO → Developer Tier (use at own risk)
│     └─ YES → Continue
│        ├─ Need VNet injection?
│        │  ├─ NO → Traffic level?
│        │  │  ├─ Low/Intermittent → Consumption (pay-per-use)
│        │  │  ├─ Low-Medium → Basic ($150/mo)
│        │  │  └─ Medium-High → Standard ($750+/mo)
│        │  └─ YES → Standard or Premium
│        │     ├─ Single region, <4 units → Standard ($750+/mo)
│        │     └─ Multi-region or >4 units → Premium ($3,000+/mo)
│        └─ Need multi-region?
│           ├─ YES → Premium ($3,000+/mo)
│           └─ NO → See above
```

### Use Case Matrix

| Use Case | Recommended Tier | Reasoning |
|----------|------------------|-----------|
| Development and Testing | Developer | Full features, low cost, no SLA needed |
| Prototype/POC | Consumption | Lowest cost, fast provisioning |
| Internal APIs (low traffic) | Basic | SLA, reasonable cost |
| Public APIs (moderate traffic) | Standard | Scalability, SLA, VNet option |
| Mission-critical APIs | Premium | Best SLA, multi-region, HA |
| Global APIs | Premium | Multi-region for low latency |
| Microservices Gateway | Standard/Premium | Scalability, VNet for private backends |
| Partner APIs (B2B) | Standard/Premium | SLA, security, monitoring |
| IoT/Event-driven | Consumption | Spiky traffic, auto-scale |
| Legacy Modernization | Standard | VNet for on-prem connectivity |

### Key Decision Factors

1. **SLA Requirements**
   - No SLA → Developer or Consumption
   - 99.95% → Basic or Standard
   - 99.99% → Premium (multi-region)

2. **Network Requirements**
   - Public only → Any tier
   - Private Endpoints → Any tier
   - VNet Injection → Developer, Standard, Premium

3. **Traffic Patterns**
   - Intermittent/Spiky → Consumption
   - Consistent low → Basic
   - Consistent medium-high → Standard
   - Very high → Premium

4. **Geographic Distribution**
   - Single region → Any tier
   - Multi-region → Premium only

5. **Scale Requirements**
   - <1,000 req/sec → Consumption, Developer, Basic
   - 1,000-2,500 req/sec → Standard
   - >2,500 req/sec → Premium

6. **Budget**
   - <$100/mo → Consumption or Developer
   - $100-$1,000/mo → Basic or Standard
   - >$1,000/mo → Premium

## Migration Between Tiers

### Supported Migrations

| From | To | Supported | Notes |
|------|----|-----------| ------|
| Developer | Basic | ✅ | Straightforward upgrade |
| Developer | Standard | ✅ | Straightforward upgrade |
| Developer | Premium | ✅ | Straightforward upgrade |
| Basic | Standard | ✅ | Straightforward upgrade |
| Basic | Premium | ✅ | Straightforward upgrade |
| Standard | Premium | ✅ | Straightforward upgrade |
| Standard | Basic | ✅ | Downgrade (check scale) |
| Premium | Standard | ✅ | Downgrade (lose multi-region) |
| Consumption | Any | ❌ | Requires re-creation |
| Any | Consumption | ❌ | Requires re-creation |

### Migration Process

**Upgrading (e.g., Basic → Standard):**

```bash
# Via Azure CLI
az apim update \
  --name apim-instance \
  --resource-group rg-apim \
  --sku-name Standard \
  --sku-capacity 1

# Or via Bicep
resource apim 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  name: 'apim-instance'
  properties: {
    sku: {
      name: 'Standard'
      capacity: 1
    }
  }
}
```

**Downtime**: Typically 15-45 minutes during tier change

### Consumption Tier Migration

**To Migrate FROM Consumption:**
1. Export APIs and policies (backup)
2. Create new APIM instance in desired tier
3. Import APIs and policies
4. Update DNS/clients to point to new instance
5. Delete old Consumption instance

**To Migrate TO Consumption:**
- Similar process as above (re-creation required)
- Not recommended for production workloads

## Best Practices

1. **Start with Lower Tier**: Upgrade as needs grow
2. **Use Developer for Non-Prod**: Save costs on dev/test environments
3. **Monitor Capacity**: Scale before hitting limits
4. **Plan for Growth**: Consider future needs in initial tier selection
5. **Test Migration**: Test tier changes in dev environment first
6. **Budget for Premium**: If multi-region is future requirement
7. **Use Consumption Wisely**: Great for variable traffic, but understand cold start
8. **Document Requirements**: Maintain clear justification for tier selection

## Additional Resources

- [Official Pricing Page](https://azure.microsoft.com/pricing/details/api-management/)
- [Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)
- [Capacity Metrics](https://learn.microsoft.com/azure/api-management/api-management-capacity)
- [Feature Comparison](https://learn.microsoft.com/azure/api-management/api-management-features)

## Next Steps

- [Observability](observability.md) - Monitor usage and performance to inform scaling decisions
- [Networking](networking.md) - Understand network requirements for tier selection
- [Concepts](concepts.md) - Learn about features available in each tier

---

**Choose wisely!** Tier selection impacts cost, features, and migration complexity.
