# Azure API Management Tiers and SKUs

This guide helps you choose the right Azure API Management tier for your needs, comparing features, limits, and costs.

> **⚠️ Educational Disclaimer**: This repository is provided for educational and learning purposes only. All content, including pricing estimates, tier recommendations, and infrastructure templates, should be validated and adapted for your specific production requirements. Azure API Management features, pricing, and best practices evolve frequently—always consult the <a href="https://learn.microsoft.com/azure/api-management/">official Azure documentation</a> and <a href="https://azure.microsoft.com/pricing/calculator/">Azure Pricing Calculator</a> for the most current information before making production decisions.

## Table of Contents
- [Tier Overview](#tier-overview)
- [Feature Comparison](#feature-comparison)
- [Capacity and Scale](#capacity-and-scale)
- [Pricing Comparison](#pricing-comparison)
- [Choosing the Right Tier](#choosing-the-right-tier)
- [Migration Between Tiers](#migration-between-tiers)

## Tier Overview

Azure API Management offers multiple pricing tiers designed for different scenarios. Classic tiers (also called **v1** tiers: Consumption, Developer, Basic, Standard, Premium) provide fixed-capacity or serverless models, while v2 tiers (Basic v2, Standard v2, Premium v2) introduced in 2024-2025 run on a newer, faster underlying platform with enhanced scalability and faster provisioning.

> **v1 vs v2 Platform**: The v1 (classic) and v2 tiers run on fundamentally different underlying platforms. The v2 platform is significantly faster and provisions in 5-15 minutes vs 30-45 minutes for classic tiers. Microsoft is actively working toward feature parity between v1 and v2, with v2 gaining networking and enterprise features over time. Notably, **there is no Developer tier in v2** and one is not planned—use the Developer classic tier for non-production environments.

### Classic Tiers (v1)

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
| **Basic v2** | Dev/test and cost-optimized production | Fixed base fee + request tiers | Auto-scaling, 99.95% SLA |
| **Standard v2** | Production with private backend access | Fixed base fee + request tiers | Outbound VNet integration, private endpoints, zone redundancy, 99.95% SLA |
| **Premium v2** | Enterprise with full VNet isolation | See pricing calculator | Full VNet injection, workspaces, zone redundancy, 99.99% SLA |

> **v2 Pricing Model**: Basic v2 and Standard v2 use a **fixed base monthly fee plus tiered request pricing**—unlike pure consumption, there is a predictable base cost regardless of usage. Premium v2 follows a different pricing structure; always check the [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) for up-to-date pricing details.

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

**Enterprise-grade production tier** with backend VNet integration on the v2 platform.

**Key Characteristics:**
- **Capacity**: Auto-scaling based on demand
- **SLA**: 99.95%
- **Pricing**: Fixed base fee + tiered request pricing
- **VNet integration (outbound)**: Supported — the gateway remains publicly accessible; backends can be privately connected
- **Private endpoints (inbound)**: Supported
- **Zone redundancy**: Supported
- **Provisioning**: Fast deployment (5-15 minutes)

> **VNet integration vs. VNet injection**: Standard v2 supports **outbound VNet integration** — API Management can reach backends in a private VNet, but the gateway endpoint itself remains publicly accessible from the internet. This is different from VNet injection (available in Developer, Premium, and Premium v2) where the entire instance is deployed inside a VNet with full traffic isolation.

**Use Cases:**
- Enterprise production workloads requiring private backend connectivity
- Applications needing zone redundancy for high availability
- Workloads where the gateway is public but backends are network-isolated

**Limitations:**
- No VNet injection (gateway endpoint is always public)
- No multi-region deployment (use classic Premium for multi-region)

**Pros:**
- ✅ Outbound VNet integration for private backend connectivity
- ✅ Inbound private endpoints for secure client access
- ✅ Zone redundancy for high availability
- ✅ Auto-scaling without capacity unit management
- ✅ SLA included (99.95%)
- ✅ Fast provisioning

**Cons:**
- ❌ No full VNet injection (gateway remains publicly accessible)
- ❌ No multi-region deployment
- ❌ Higher base cost than Basic v2

### Premium v2 Tier

**Enterprise-grade tier with full VNet isolation** on the v2 platform. Generally Available (GA).

**Key Characteristics:**
- **Capacity**: Auto-scaling up to 30 units
- **SLA**: 99.99%
- **Pricing**: Check [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) (different structure from Basic v2/Standard v2)
- **VNet injection**: Supported — full inbound+outbound isolation inside a VNet
- **VNet integration (outbound)**: Supported
- **Private Endpoints (inbound)**: Supported (when not using VNet injection)
- **Workspaces**: Supported
- **Zone redundancy**: Supported
- **Provisioning**: Fast deployment (5-15 minutes)

> **Note**: Unlike classic Premium, Premium v2 does **not** support multi-region deployment or self-hosted gateways (as of 2025). Check the [official docs](https://learn.microsoft.com/azure/api-management/v2-service-tiers-overview) for current availability.

**Use Cases:**
- Enterprise production requiring full network isolation (VNet injection)
- High-availability workloads needing zone redundancy
- Organizations using workspaces for federated API management

**Limitations:**
- No multi-region deployment (use classic Premium for multi-region)
- No self-hosted gateway support

**Pros:**
- ✅ Full VNet injection for complete network isolation
- ✅ Highest SLA in the v2 tier family (99.99%)
- ✅ Workspaces support
- ✅ Zone redundancy
- ✅ Auto-scaling without capacity unit management
- ✅ Fast provisioning

**Cons:**
- ❌ No multi-region deployment
- ❌ No self-hosted gateway
- ❌ Highest cost in v2 family

## Feature Comparison

### Classic Tiers vs v2 Tiers

| Feature | Consumption | Developer | Basic | Standard | Premium | Basic v2 | Standard v2 | Premium v2 |
|---------|-------------|-----------|-------|----------|---------|----------|-------------|------------|
| **SLA** | None | None | 99.95% | 99.95% | 99.99%* | 99.95% | 99.95% | 99.99% |
| **Pricing Model** | Pay-per-call | Fixed | Fixed | Fixed | Fixed | Base + request tiers | Base + request tiers | Base + request tiers |
| **Auto-scaling** | Yes | No | No | No | Manual | Yes | Yes | Yes |
| **Max Scale** | Auto | 1 unit | 2 units | 4 units | 12+ units/region | Auto | Auto | Auto |
| **Max Requests/sec** | 1,000 | 500 | 1,000 | 2,500 | 4,000+/unit | Auto | Auto | Auto |
| **Custom Domains** | Limited | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **VNet Injection** | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ | ✅ |
| **VNet Integration (outbound)** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| **Private Endpoints** | ❌ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ |
| **Multi-region** | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| **Availability Zones** | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ | ✅ |
| **Self-hosted Gateway** | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| **Workspaces** | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ✅ |
| **Built-in Cache** | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **External Cache (Redis)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Developer Portal** | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **OAuth 2.0 / JWT** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Client Certificates** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Managed Identity** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Backup/Restore** | ❌ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| **Git Configuration** | ❌ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| **Provisioning Time** | 5 min | 30-45 min | 30-45 min | 30-45 min | 30-45 min | 5-15 min | 5-15 min | 5-15 min |

*99.99% SLA with multi-region deployment

> **Networking in v1 vs v2**: VNet injection (full inbound+outbound isolation) is available only on **Developer** and **Premium** classic tiers, and **Premium v2**. **Standard v2** and **Premium v2** also support **outbound VNet integration** (backend connectivity only, gateway remains public). Inbound **Private Endpoints** are available on Developer, Basic, Standard, Standard v2, Premium, and Premium v2 — but NOT on Consumption or Basic v2. See the [official feature comparison](https://learn.microsoft.com/azure/api-management/api-management-features) for details.

> **Self-hosted gateway** is only available on **Developer** and **Premium** classic tiers — not on Basic/Standard classic, and not on any v2 tier.

> **Workspaces** are only available on **Premium** and **Premium v2** tiers.

**Key Differences:**
- **v2 tiers** run on a newer, faster underlying platform (not the same as the stv2 compute platform for classic tiers)
- **v2 tiers** provision significantly faster (5-15 minutes vs 30-45 minutes for classic)
- **v2 tiers** auto-scale without manual capacity unit management
- **Standard v2** supports outbound VNet integration (backend private connectivity) but the gateway remains publicly accessible; **Premium v2** adds full VNet injection
- **Standard v2** and **Premium v2** include availability zones; classic Standard does not
- **No Developer tier in v2** — use the classic Developer tier for non-production environments
- **Backup/Restore and Git configuration** are not available in any v2 tier
- **Multi-region deployment** is only available on classic **Premium** tier

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

> **Important**: Pricing shown is indicative based on US East region as of 2026. Actual costs vary significantly by region, usage patterns, and Azure subscription type. Always use the [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) for accurate estimates.

### Classic Tiers - Cost Breakdown (Approximate - USD, East US 2026)

| Tier | Monthly Base | Per Unit/Month | Additional Costs |
|------|--------------|----------------|------------------|
| **Consumption** | $0 | Pay per use | ~$3.50 per million calls + ~$0.14/gateway hour |
| **Developer** | ~$50 | N/A (fixed 1 unit) | None |
| **Basic** | ~$150 | ~$150 | None |
| **Standard** | ~$750 | ~$750 | None |
| **Premium** | ~$3,000 | ~$3,000 | Multi-region: +~$3,000 per additional region |

### v2 Tiers - Pricing Model (2026)

v2 tiers (Basic v2 and Standard v2) use a **fixed base monthly fee plus tiered request pricing**. This differs from the classic Consumption tier (pure pay-per-call) and from classic fixed-unit tiers. Premium v2 has a different pricing structure.

| Tier | Pricing Model | SLA |
|------|---------------|-----|
| **Basic v2** | Fixed base fee + tiered request pricing | 99.95% |
| **Standard v2** | Fixed base fee + tiered request pricing | 99.95% |
| **Premium v2** | Check Azure Pricing Calculator (different structure) | 99.99% |

> **Note**: v2 pricing details evolve. Always consult the [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) and the [official pricing page](https://azure.microsoft.com/pricing/details/api-management/) for current rates.

**Cost Optimization Considerations:**
- v2 tiers eliminate the need to pre-provision capacity units
- Faster provisioning (5-15 min) reduces deployment and testing costs
- Compare v2 fixed base + request tiers vs classic fixed-unit pricing for your specific request volume

### Cost Examples

> **Note**: These are illustrative examples. Actual costs depend on region, usage patterns, and specific features used. Always calculate costs for your specific scenario.

**Scenario 1: Development/Testing**
- **Best Tier**: Developer (classic)
- **Monthly Cost**: ~$50 (fixed)
- **Rationale**: Full features, no SLA needed for dev; no Developer equivalent in v2

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
│  ├─ NO → Developer Tier (~$50/mo) [no v2 Developer equivalent]
│  └─ YES → Need SLA?
│     ├─ NO → Developer Tier (use at own risk)
│     └─ YES → Prefer v2 platform (faster, auto-scaling)?
│        ├─ YES → Need VNet injection?
│        │  ├─ NO → Need Private Endpoint?
│        │  │  ├─ NO → Basic v2 (base fee + request tiers, 99.95% SLA)
│        │  │  └─ YES → Standard v2 or Premium v2
│        │  └─ YES → Standard v2 (VNet, zones, 99.95% SLA)
│        └─ NO (prefer classic fixed pricing) → Continue
│           ├─ Need VNet injection?
│           │  ├─ NO → Traffic level?
│           │  │  ├─ Low/Intermittent → Consumption (pay-per-use, no SLA)
│           │  │  ├─ Low-Medium → Basic (~$150/mo)
│           │  │  └─ Medium-High → Standard (~$750+/mo)
│           │  └─ YES → Standard or Premium
│           │     ├─ Single region, <4 units → Standard (~$750+/mo)
│           │     └─ Multi-region or >4 units → Premium (~$3,000+/mo)
│           └─ Need multi-region?
│              ├─ YES → Premium (~$3,000+/mo) [only classic Premium supports multi-region]
│              └─ NO → See above
```

### Use Case Matrix

| Use Case | Recommended Tier | Reasoning |
|----------|------------------|-----------|
| Development and Testing | Developer (classic) | Full features, low cost, no SLA needed; no v2 Developer tier exists |
| Prototype/POC | Consumption | Lowest cost, fast provisioning, no SLA |
| Internal APIs (low traffic) | Basic or Basic v2 | SLA, reasonable cost; v2 for auto-scaling |
| Public APIs (moderate traffic) | Standard, Standard v2 | Scalability, SLA; v2 for auto-scaling + VNet |
| Mission-critical APIs | Premium or Standard v2 | Premium for multi-region; Standard v2 for single region with zones |
| Global APIs | Premium (classic) | Only classic Premium supports multi-region deployment |
| Microservices Gateway | Standard/Premium/Standard v2 | Scalability, VNet for private backends |
| Partner APIs (B2B) | Standard/Premium/Standard v2 | SLA, security, monitoring |
| IoT/Event-driven | Consumption or Basic v2 | Spiky traffic, auto-scale; v2 adds SLA |
| Legacy Modernization | Standard or Standard v2 | VNet for on-prem connectivity |
| Variable Enterprise Workload | Basic v2 or Standard v2 | Auto-scaling, SLA, v2 platform speed |
| Cost-sensitive Production | Basic v2 | Production SLA with v2 auto-scaling |

### Key Decision Factors

1. **SLA Requirements**
   - No SLA → Developer or Consumption
   - 99.95% → Basic or Standard
   - 99.99% → Premium (multi-region)

2. **Network Requirements**
   - Public only → Any tier
   - Private Endpoints (inbound) → Developer, Basic, Standard, Standard v2, Premium, Premium v2
   - Outbound VNet integration (reach private backends, gateway stays public) → Standard v2, Premium v2
   - Full VNet injection (complete isolation) → Developer, Premium (classic); Premium v2

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
| Any classic | v2 tiers | ❌ | Cannot migrate; must create a new v2 instance |
| v2 tiers | classic | ❌ | Cannot migrate; must create a new classic instance |
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
- [Feature-based comparison of Azure API Management tiers](https://learn.microsoft.com/azure/api-management/api-management-features)
- [Azure API Management v2 tiers overview](https://learn.microsoft.com/azure/api-management/v2-service-tiers-overview)
- [Capacity metrics and scaling](https://learn.microsoft.com/azure/api-management/api-management-capacity)
- [Upgrade and scale an Azure API Management instance](https://learn.microsoft.com/azure/api-management/upgrade-and-scale)
- [Azure API Management service limits](https://learn.microsoft.com/azure/api-management/service-limits)
- [Autoscale an Azure API Management instance](https://learn.microsoft.com/azure/api-management/api-management-howto-autoscale)

## Next Steps

- [Observability](observability.md) - Monitor usage and performance to inform scaling decisions
- [Networking](networking.md) - Understand network requirements for tier selection
- [Concepts](concepts.md) - Learn about features available in each tier

---

**Choose wisely!** Tier selection impacts cost, features, and migration complexity. For production deployments, always validate tier selection with current Azure documentation and pricing calculators, as cloud offerings evolve continuously.
