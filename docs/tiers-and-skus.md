# Azure API Management Tiers and SKUs

This guide helps you choose the right Azure API Management tier for your needs, comparing features, limits, and costs.

> **⚠️ Important**: This document provides indicative pricing and tier comparisons based on 2026 information for US regions. Azure API Management pricing, features, and tier availability vary by region and are subject to change. Always consult the [official Azure Pricing page](https://azure.microsoft.com/pricing/details/api-management/) and use the [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) for current, region-specific pricing and feature availability before making deployment decisions.

## Table of Contents
- [Tier Overview](#tier-overview)
- [Feature Comparison](#feature-comparison)
- [Capacity and Scale](#capacity-and-scale)
- [Pricing Comparison](#pricing-comparison)
- [Choosing the Right Tier](#choosing-the-right-tier)
- [Migration Between Tiers](#migration-between-tiers)

## Tier Overview

Azure API Management offers multiple pricing tiers designed for different scenarios. Classic tiers (Consumption, Developer, Basic, Standard, Premium) provide fixed-capacity or serverless models, while v2 tiers (Basic v2, Standard v2) introduced in 2024-2025 offer consumption-based pricing with enhanced scalability.

### Classic Tiers

| Tier | Best For | Pricing Model | Starting Price* |
|------|----------|---------------|----------------|
| **Consumption** | Serverless, event-driven workloads | Pay-per-execution | ~$3.50/million calls |
| **Developer** | Development and testing | Fixed monthly | ~$50/month |
| **Basic** | Production workloads (small) | Fixed monthly | ~$150/month |
| **Standard** | Production workloads (medium) | Fixed monthly | ~$750/month |
| **Premium** | Enterprise production workloads | Fixed monthly | ~$3,000/month |

### v2 Tiers (2024+)

| Tier | Best For | Pricing Model | Key Features |
|------|----------|---------------|--------------|
| **Basic v2** | Cost-optimized production | Consumption-based | Auto-scaling, 99.95% SLA, cost-effective |
| **Standard v2** | Enterprise production | Consumption-based | VNet injection, zone redundancy, 99.95% SLA |

*Prices are indicative and based on US East region (2026). Regional pricing varies significantly. Check the [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) for accurate cost estimates specific to your region and usage patterns.

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

### Basic v2 Tier

**Cost-optimized consumption-based production tier** introduced in 2024-2025.

**Key Characteristics:**
- **Capacity**: Auto-scaling based on demand
- **SLA**: 99.95%
- **Pricing**: Consumption-based (pay for actual usage)
- **Provisioning**: Fast deployment (5-15 minutes)
- **Custom domains**: Supported

**Use Cases:**
- Production workloads with predictable traffic patterns
- Cost-conscious production deployments
- Workloads requiring SLA without VNet requirements
- Applications needing auto-scaling without managing capacity units

**Limitations:**
- No VNet injection
- No multi-region deployment
- No availability zones

**Pros:**
- ✅ Consumption-based pricing (pay for what you use)
- ✅ Auto-scaling without manual capacity management
- ✅ SLA included (99.95%)
- ✅ Fast provisioning compared to classic tiers
- ✅ Lower cost than fixed-capacity Basic tier for variable workloads

**Cons:**
- ❌ No VNet injection
- ❌ Single region only
- ❌ No availability zones

### Standard v2 Tier

**Enterprise-grade consumption-based production tier** with advanced networking.

**Key Characteristics:**
- **Capacity**: Auto-scaling based on demand
- **SLA**: 99.95%
- **Pricing**: Consumption-based (pay for actual usage)
- **VNet injection**: Supported
- **Zone redundancy**: Supported
- **Provisioning**: Fast deployment (5-15 minutes)

**Use Cases:**
- Enterprise production workloads requiring VNet integration
- Applications with variable traffic needing cost optimization
- Workloads requiring zone redundancy for high availability
- Private APIs with backend connectivity requirements
- Production workloads prioritizing consumption-based pricing over fixed costs

**Limitations:**
- No multi-region deployment (use Premium for multi-region)
- Higher per-request costs compared to v2 Basic at high volumes

**Pros:**
- ✅ Consumption-based pricing with enterprise features
- ✅ VNet injection for private connectivity
- ✅ Zone redundancy for high availability
- ✅ Auto-scaling without capacity unit management
- ✅ SLA included (99.95%)
- ✅ Fast provisioning
- ✅ Cost-effective for variable enterprise workloads

**Cons:**
- ❌ No multi-region deployment
- ❌ Higher base cost than Basic v2

## Feature Comparison

### Classic Tiers vs v2 Tiers

| Feature | Consumption | Developer | Basic | Standard | Premium | Basic v2 | Standard v2 |
|---------|-------------|-----------|-------|----------|---------|----------|-------------|
| **SLA** | None | None | 99.95% | 99.95% | 99.99%* | 99.95% | 99.95% |
| **Pricing Model** | Pay-per-call | Fixed | Fixed | Fixed | Fixed | Consumption | Consumption |
| **Auto-scaling** | Yes | No | No | No | Manual | Yes | Yes |
| **Max Scale** | Auto | 1 unit | 2 units | 4 units | 12+ units/region | Auto | Auto |
| **Max Requests/sec** | 1,000 | 500 | 1,000 | 2,500 | 4,000+/unit | Auto | Auto |
| **Custom Domains** | Limited | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **VNet Injection** | ❌ | ✅ | ❌ | ✅ | ✅ | ❌ | ✅ |
| **Private Endpoints** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Multi-region** | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ |
| **Availability Zones** | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ |
| **Self-hosted Gateway** | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Built-in Cache** | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **External Cache (Redis)** | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Developer Portal** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **OAuth 2.0 / JWT** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Client Certificates** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Managed Identity** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Backup/Restore** | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Git Configuration** | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Provisioning Time** | 5 min | 30-45 min | 30-45 min | 30-45 min | 30-45 min | 5-15 min | 5-15 min |

*99.99% SLA with multi-region deployment

**Key Differences:**
- **v2 tiers** use consumption-based pricing instead of fixed monthly costs
- **v2 tiers** provision significantly faster (5-15 minutes vs 30-45 minutes)
- **v2 tiers** auto-scale without manual capacity unit management
- **Standard v2** includes zone redundancy; classic Standard does not

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
- **Classic tiers**: Manual scaling only—monitor metrics and scale proactively
- **v2 tiers**: Automatic scaling based on demand (0-10 units for Basic v2, 0-100 units for Standard v2)
- **Consumption tier**: Serverless auto-scaling (scales to zero when idle)

## Pricing Comparison

> **Important**: Pricing shown is indicative based on US East region as of 2026. Actual costs vary significantly by region, usage patterns, and Azure subscription type. v2 tier pricing is consumption-based and depends on request volume, compute usage, and feature utilization. Always use the [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) for accurate estimates.

### Classic Tiers - Cost Breakdown (Approximate - USD, East US 2026)

| Tier | Monthly Base | Per Unit/Month | Additional Costs |
|------|--------------|----------------|------------------|
| **Consumption** | $0 | Pay per use | ~$3.50 per million calls + ~$0.14/gateway hour |
| **Developer** | ~$50 | N/A (fixed 1 unit) | None |
| **Basic** | ~$150 | ~$150 | None |
| **Standard** | ~$750 | ~$750 | None |
| **Premium** | ~$3,000 | ~$3,000 | Multi-region: +~$3,000 per additional region |

### v2 Tiers - Consumption-Based Pricing (2026)

v2 tiers use consumption-based pricing that scales with actual usage:

| Tier | Pricing Model | Indicative Cost Range* | SLA |
|------|---------------|----------------------|-----|
| **Basic v2** | Consumption-based | Varies by usage; typically lower than fixed Basic for variable workloads | 99.95% |
| **Standard v2** | Consumption-based | Varies by usage; cost-effective for enterprise features with variable traffic | 99.95% |

*v2 pricing is based on:
- Number of API requests
- Compute usage (processing time)
- Data transfer
- Feature utilization (VNet injection, zone redundancy, etc.)

**Cost Optimization Considerations:**
- v2 tiers are generally more cost-effective than classic fixed-price tiers for workloads with variable traffic
- For predictable, high-volume workloads, compare v2 consumption costs with classic tier fixed pricing
- v2 tiers eliminate the need to pre-provision capacity units
- Faster provisioning (5-15 min) reduces deployment and testing costs

### Cost Examples

> **Note**: These are illustrative examples. Actual costs depend on region, usage patterns, and specific features used. Always calculate costs for your specific scenario.

**Scenario 1: Development/Testing**
- **Best Tier**: Developer
- **Monthly Cost**: ~$50 (fixed)
- **Rationale**: Full features, no SLA needed for dev

**Scenario 2: Startup with 10M requests/month (variable traffic)**
- **Consumption**: ~$35-50/month (10 × $3.50 + gateway hours)
- **Basic**: ~$150/month (fixed)
- **Basic v2**: ~$40-80/month (consumption-based, varies with traffic pattern)
- **Best Choice**: Basic v2 or Consumption (for variable traffic), Basic classic (for consistent traffic with SLA)

**Scenario 3: Medium Enterprise with 500M requests/month**
- **Standard (4 units)**: 4 × ~$750 = ~$3,000/month (fixed)
- **Premium (2 units)**: 2 × ~$3,000 = ~$6,000/month (fixed)
- **Standard v2**: Consumption-based, potentially ~$2,000-4,000/month depending on usage patterns
- **Best Choice**: Standard v2 (if single region with variable traffic), Standard classic (predictable high volume), Premium (if multi-region or highest SLA needed)

**Scenario 4: Global enterprise with multi-region**
- **Premium (2 regions, 2 units each)**: 2 regions × 2 units × ~$3,000 = ~$12,000/month
- **Benefits**: 99.99% SLA, low latency globally, disaster recovery
- **Note**: Multi-region currently requires Premium tier (not available in v2 tiers as of 2026)

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
│  ├─ NO → Developer Tier (~$50/mo)
│  └─ YES → Need SLA?
│     ├─ NO → Developer Tier (use at own risk)
│     └─ YES → Continue
│        ├─ Prefer consumption-based pricing?
│        │  ├─ YES → Need VNet injection?
│        │  │  ├─ NO → Basic v2 (consumption-based, 99.95% SLA)
│        │  │  └─ YES → Standard v2 (consumption-based, VNet, zones)
│        │  └─ NO (prefer fixed pricing) → Continue
│        │     ├─ Need VNet injection?
│        │     │  ├─ NO → Traffic level?
│        │     │  │  ├─ Low/Intermittent → Consumption (pay-per-use, no SLA)
│        │     │  │  ├─ Low-Medium → Basic (~$150/mo)
│        │     │  │  └─ Medium-High → Standard (~$750+/mo)
│        │     │  └─ YES → Standard or Premium
│        │     │     ├─ Single region, <4 units → Standard (~$750+/mo)
│        │     │     └─ Multi-region or >4 units → Premium (~$3,000+/mo)
│        │     └─ Need multi-region?
│        │        ├─ YES → Premium (~$3,000+/mo)
│        │        └─ NO → See above
```

### Use Case Matrix

| Use Case | Recommended Tier | Reasoning |
|----------|------------------|-----------|
| Development and Testing | Developer | Full features, low cost, no SLA needed |
| Prototype/POC | Consumption | Lowest cost, fast provisioning, no SLA |
| Internal APIs (low traffic) | Basic or Basic v2 | SLA, reasonable cost; v2 for auto-scaling |
| Public APIs (moderate traffic) | Standard, Standard v2 | Scalability, SLA; v2 for consumption pricing + VNet |
| Mission-critical APIs | Premium or Standard v2 | Premium for multi-region; Standard v2 for single region with zones |
| Global APIs | Premium | Multi-region for low latency worldwide |
| Microservices Gateway | Standard/Premium/Standard v2 | Scalability, VNet for private backends |
| Partner APIs (B2B) | Standard/Premium/Standard v2 | SLA, security, monitoring; v2 for cost optimization |
| IoT/Event-driven | Consumption or Basic v2 | Spiky traffic, auto-scale; v2 adds SLA |
| Legacy Modernization | Standard or Standard v2 | VNet for on-prem connectivity; v2 for consumption pricing |
| Variable Enterprise Workload | Basic v2 or Standard v2 | Consumption-based pricing, auto-scaling, SLA |
| Cost-sensitive Production | Basic v2 | Production SLA with consumption-based cost optimization |

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
| Consumption | Any classic | ❌ | Requires re-creation |
| Any classic | Consumption | ❌ | Requires re-creation |
| Any classic | v2 tiers | ⚠️ | May require re-creation; check Azure docs |
| v2 tiers | classic | ⚠️ | May require re-creation; check Azure docs |
| Basic v2 | Standard v2 | ✅ | Typically supported |
| Standard v2 | Basic v2 | ⚠️ | Check compatibility (may lose features) |

**Note**: Migration paths between classic and v2 tiers may evolve. Always consult the [official Azure documentation](https://learn.microsoft.com/azure/api-management/) for current migration support and procedures.

**Migration Feasibility Factors:**
- **Architecture differences**: v2 tiers use a different underlying architecture than classic tiers
- **Feature availability**: Some v2 features may not map directly to classic tier equivalents
- **Networking changes**: VNet injection implementation differs between classic and v2 tiers
- **Best practice**: Test migration paths in non-production environments before production migration
- **Azure support**: Consult Azure support for guidance on complex migration scenarios

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

1. **Start with Lower Tier**: Upgrade as needs grow; Developer for dev/test, Basic v2 or Consumption for initial production
2. **Use Developer for Non-Prod**: Save costs on dev/test environments
3. **Consider v2 Tiers**: Evaluate consumption-based pricing for cost optimization and auto-scaling benefits
4. **Monitor Capacity**: For classic tiers, scale before hitting limits; v2 tiers auto-scale
5. **Plan for Growth**: Consider future needs in initial tier selection; v2 tiers provide flexibility
6. **Budget for Premium**: If multi-region is a future requirement (not available in v2 as of 2026)
7. **Use Consumption or v2 Wisely**: Great for variable traffic; v2 adds SLA and faster provisioning
8. **Document Requirements**: Maintain clear justification for tier selection
9. **Regional Pricing Matters**: Verify pricing in your target region—costs vary significantly
10. **Validate Production Choices**: Test tier performance and costs in non-production before committing

### v2 Tier Best Practices

- **Leverage Auto-scaling**: v2 tiers eliminate manual capacity management
- **Monitor Consumption**: Track actual usage to optimize costs
- **Fast Provisioning**: Use for rapid deployment and testing scenarios
- **Zone Redundancy**: Use Standard v2 for high availability without multi-region complexity
- **Cost Comparison**: Compare v2 consumption costs with classic fixed pricing for your specific workload

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

**Choose wisely!** Tier selection impacts cost, features, and migration complexity. For production deployments, always validate tier selection with current Azure documentation and pricing calculators, as cloud offerings evolve continuously.
