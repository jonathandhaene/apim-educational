# Azure API Management Educational Repository

Welcome to the Azure API Management (APIM) Educational Repository! This comprehensive learning resource provides hands-on labs, infrastructure templates, policy examples, and best practices for working with Azure API Management.

> **⚠️ Educational Disclaimer**: This repository is provided for educational and learning purposes only. All content, including pricing estimates, tier recommendations, and infrastructure templates, should be validated and adapted for your specific production requirements. Azure API Management features, pricing, and best practices evolve frequently—always consult the [official Azure documentation](https://learn.microsoft.com/azure/api-management/) and [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) for the most current information before making production decisions.

## 📋 Repository Purpose

This repository serves as:
- **Learning Resource**: Step-by-step labs and guides for APIM concepts
- **Reference Implementation**: Production-ready Bicep and Terraform templates
- **Policy Library**: Curated collection of APIM policy examples and patterns
- **Testing Framework**: Sample test suites and CI/CD workflows
- **Best Practices**: Security, networking, and operational guidance

## 🌟 Why Azure API Management?

Azure API Management is Microsoft's enterprise-grade API gateway solution, offering powerful capabilities for organizations of all sizes:

### Key Advantages

**🚀 Comprehensive API Lifecycle Management**
- **Unified Gateway**: Single point of entry for all your APIs across cloud, on-premises, and hybrid environments
- **Developer Portal**: Self-service portal for API discovery, documentation, and onboarding
- **API Versioning**: Built-in support for multiple API versions and revisions with seamless deployment strategies
- **Analytics & Insights**: Deep telemetry with Azure Monitor, Application Insights, and custom dashboards

**🔒 Enterprise-Grade Security**
- **Authentication & Authorization**: OAuth 2.0, OpenID Connect, JWT validation, and Azure AD integration
- **Subscription Keys**: Built-in API key management with per-product/per-API granularity
- **Rate Limiting & Quotas**: Protect backends with flexible throttling policies
- **IP Filtering & WAF**: Network security with Azure Firewall and Front Door WAF integration
- **Key Vault Integration**: Secure secrets management with Azure Key Vault

**🌐 Global Distribution & High Availability**
- **Multi-Region Deployment**: Deploy to multiple Azure regions for low latency and disaster recovery
- **Zone Redundancy**: Availability zone support in v2 tiers for 99.99% SLA
- **Self-Hosted Gateway**: Extend APIM to on-premises and edge locations
- **CDN Integration**: Cache responses globally with Azure Front Door and CDN

**📊 Advanced Policy Engine**
- **Transformation**: Request/response manipulation, protocol mediation, XML/JSON conversion
- **Caching**: Built-in response caching to reduce backend load and improve performance
- **Mock Responses**: API prototyping without backend implementation
- **Circuit Breaker**: Resilience patterns with retry, timeout, and circuit breaker policies
- **AI Gateway**: Token management, semantic caching, and load balancing for Azure OpenAI

**💰 Flexible Pricing & Deployment Options**
- **Consumption Tier**: Serverless, pay-per-execution for variable workloads
- **v2 Tiers (2024+)**: Auto-scaling with consumption-based pricing (Basic v2, Standard v2)
- **Classic Tiers**: Fixed-capacity options (Developer, Basic, Standard, Premium)
- **Cost Optimization**: Right-size deployments from development to enterprise scale

**🔗 Seamless Azure Integration**
- **Native Integration**: Works seamlessly with Azure Functions, Logic Apps, App Services, AKS
- **API Center**: Centralized API inventory and governance across your organization
- **DevOps**: Full support for CI/CD with ARM/Bicep/Terraform and Azure DevOps/GitHub Actions
- **Managed Identity**: Simplified authentication to Azure services without credentials

**📈 Production-Ready Features**
- **99.99% SLA**: Available with Premium and v2 tiers for mission-critical workloads
- **Auto-Scaling**: Automatic scale-out in v2 tiers based on demand
- **Private Endpoints**: Secure, private connectivity with VNet integration
- **Custom Domains**: Support for multiple custom domains with SSL/TLS certificates
- **Backup & Restore**: Built-in backup capabilities for configuration and policies

### When to Choose Azure APIM

✅ **Ideal for:**
- Organizations already using Azure or Microsoft cloud services
- Enterprises requiring enterprise-grade security and compliance (SOC 2, ISO, HIPAA, PCI)
- Teams needing comprehensive API lifecycle management
- Multi-cloud and hybrid scenarios with self-hosted gateway
- Azure OpenAI implementations requiring token management and semantic caching
- Microservices architectures on Azure Kubernetes Service (AKS)

⚠️ **Consider alternatives if:**
- You need a pure open-source solution (consider Kong, Tyk, or API Gateway patterns)
- Your infrastructure is entirely outside Azure (though self-hosted gateway helps)
- You have simple API proxying needs without policy requirements

## 🗂️ Repository Structure

```
apim-educational/
├── docs/                      # Core documentation and guides
│   ├── concepts.md           # APIM fundamentals and architecture
│   ├── networking.md         # Network configurations and patterns
│   ├── security.md           # Security best practices
│   ├── tiers-and-skus.md     # SKU comparison and cost guidance
│   ├── observability.md      # Monitoring and diagnostics
│   ├── troubleshooting.md    # Common issues and solutions
│   ├── workspaces.md         # APIM Workspaces for multi-environment management
│   ├── api-center.md         # Azure API Center integration
│   ├── front-door.md         # Front Door + APIM patterns
│   ├── ai-gateway.md         # AI Gateway capabilities
│   ├── migration/            # Migration guides
│   │   ├── aws-to-apim.md    # AWS API Gateway to APIM migration
│   │   └── google-to-apim.md # Google API to APIM migration
│   └── diagrams/             # Architecture diagrams
├── infra/                     # Infrastructure as Code
│   ├── bicep/                # Modular Bicep templates
│   └── terraform/            # Terraform modules
├── labs/                      # Hands-on guided labs
│   ├── lab-01-beginner/      # Getting started
│   ├── lab-02-intermediate/  # Diagnostics and security
│   ├── lab-03-advanced/      # VNet and Key Vault
│   ├── lab-04-expert/        # Self-hosted gateway and Front Door
│   ├── lab-05-ops-architecture/ # Operations and best practices
│   └── lab-06-workspaces/    # APIM Workspaces for environment segmentation
├── src/                       # Sample applications
│   ├── functions-sample/     # Azure Function example with Docker/K8s
│   └── third-party-integrations/ # Twilio SMS and Stripe payments
├── frontend-samples/          # Frontend integration examples
│   ├── react-sample/         # React + APIM integration
│   └── angular-sample/       # Angular + APIM integration
├── policies/                  # APIM policy examples
│   └── fragments/            # Reusable policy fragments
├── gateway/                   # Self-hosted gateway samples
│   ├── docker-compose.yml    # Local development
│   └── k8s/                  # Kubernetes deployment
├── tests/                     # Testing assets
│   ├── postman/              # Postman collections
│   ├── rest-client/          # VS Code REST Client files
│   └── k6/                   # Load testing scripts
├── scripts/                   # Automation scripts
│   ├── deploy-apim.ps1/.sh   # Deployment scripts
│   ├── import-openapi.ps1/.sh # API import automation
│   └── sync-api-center.ps1/.sh # API Center sync
└── tools/                     # Migration and utility tools
    └── migration/            # API migration helpers
```

## 🚀 Quick Start

### Prerequisites

- **Azure Subscription**: [Free account](https://azure.microsoft.com/free/) available
- **Azure CLI**: [Install Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)
- **Bicep** or **Terraform**: Choose your preferred IaC tool
- **VS Code** (recommended): With REST Client extension
- **Git**: For cloning this repository

### Option 1: Deploy with Bicep

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "<your-subscription-id>"

# Deploy a development APIM instance
cd infra/bicep
./scripts/deploy-apim.sh -p params/public-dev.bicepparam -g rg-apim-dev -l eastus
```

### Option 2: Deploy with Terraform

```bash
# Navigate to Terraform directory
cd infra/terraform

# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var-file="public-dev.tfvars"

# Apply configuration
terraform apply -var-file="public-dev.tfvars"
```

### Run Your First Lab

Start with our comprehensive hands-on labs that take you from beginner to expert:

**[📚 View All Labs](labs/README.md)** - Six progressive labs covering:
1. **[Lab 1: Beginner](labs/lab-01-beginner/README.md)** - Deploy APIM, import API, basic policies
2. **[Lab 2: Intermediate](labs/lab-02-intermediate/README.md)** - Diagnostics, JWT, load testing
3. **[Lab 3: Advanced](labs/lab-03-advanced/README.md)** - VNet, private endpoints, Key Vault
4. **[Lab 4: Expert](labs/lab-04-expert/README.md)** - Self-hosted gateway, Front Door, blue/green
5. **[Lab 5: Operations](labs/lab-05-ops-architecture/README.md)** - API Center, AI Gateway, best practices
6. **[Lab 6: Workspaces](labs/lab-06-workspaces/README.md)** - Multi-environment management, workspace segmentation

Or explore other resources:
1. **Navigate to labs**: `cd labs/lab-01-beginner/` - Hands-on guided learning
2. **Try frontend samples**: `cd frontend-samples/` - React and Angular examples
3. **Explore integrations**: `cd src/third-party-integrations/` - Twilio SMS and Stripe payments
4. **Containerize functions**: `cd src/functions-sample/k8s/` - Docker and Kubernetes examples
5. **Test with Postman**: Collection ready in `tests/postman/`

## 📚 Learning Path

Our structured learning path takes you from beginner to expert through six comprehensive labs. Each lab builds on concepts from previous ones:

### [Complete Lab Series →](labs/README.md)

**[Lab 1: Beginner](labs/lab-01-beginner/README.md)** (45-60 min)
- Deploy your first APIM instance (Developer or Consumption tier)
- Import a sample API using OpenAPI specification
- Apply basic policies (rate limiting, caching)
- Test with Postman or REST Client
- View logs in Application Insights

**[Lab 2: Intermediate](labs/lab-02-intermediate/README.md)** (60-90 min)
- Configure Application Insights and Log Analytics
- Implement JWT validation for OAuth/OIDC
- Apply advanced rate limiting and quota policies
- Run k6 load tests
- Analyze logs with KQL queries

**[Lab 3: Advanced](labs/lab-03-advanced/README.md)** (90-120 min)
- Configure VNet integration for private/internal mode
- Set up private endpoints with Private DNS
- Integrate Azure Key Vault for secrets management
- Implement API versioning and revision strategies
- Configure custom domains (placeholder approach)

**[Lab 4: Expert](labs/lab-04-expert/README.md)** (120-150 min)
- Deploy self-hosted gateway with Docker and Kubernetes
- Integrate Azure Front Door with WAF
- Implement blue/green deployment with revisions
- Optimize performance with caching strategies
- Configure backend pools and load balancing

**[Lab 5: Operations & Architecture](labs/lab-05-ops-architecture/README.md)** (90-120 min)
- Synchronize APIs with Azure API Center
- Implement AI Gateway policies for Azure OpenAI
- Create advanced observability dashboards with KQL
- Understand disaster recovery strategies
- Apply cost optimization techniques
- Review production readiness checklist

**[Lab 6: Workspaces](labs/lab-06-workspaces/README.md)** (60-90 min)
- Configure APIM Workspaces for multi-environment segmentation (dev/test/prod)
- Manage APIs within dedicated workspaces
- Implement workspace-specific policies and configurations
- Establish API promotion workflows across environments
- Apply workspace-based collaboration patterns for team isolation

## 🔄 Migrating to Azure APIM

**Coming from Google's API services?** We've got you covered!

### [Google API to Azure APIM Migration Guide →](docs/migration/google-to-apim.md)

Comprehensive guide covering:
- **Assessment**: Inventory APIs, products, quotas, auth patterns
- **Mapping**: Apigee/API Gateway → APIM constructs and policies
- **Migration Plan**: Step-by-step process with timelines
- **Tooling**: Scripts for OpenAPI translation and import
- **Risk Mitigation**: Compatibility notes and gotchas
- **Testing**: Validation strategies and rollback plans

**Migration Tools**: [tools/migration/](tools/migration/)
- OpenAPI translation scripts (Bash & PowerShell)
- Policy mapping templates
- Bulk import utilities

## 💰 Cost Considerations

> **⚠️ Pricing Disclaimer**: Pricing information below is indicative and based on US East region as of early 2026. Actual costs vary significantly by region, usage patterns, Azure subscription type, and promotional offers. Prices and features are subject to change. **Always use the [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) for accurate, current estimates specific to your region and requirements.**

### Tier Comparison (2026)

**Development/Learning** (lowest cost):
- **Consumption tier**: Pay-per-execution, no upfront cost (~$3.50 per million calls + gateway hours). Best for: variable traffic, development, testing, POCs
- **Developer tier**: ~$50/month fixed, includes all features except SLA and scaling. Best for: non-production environments, learning, internal tools

**Production - Classic Tiers** (fixed-capacity model):
- **Basic**: ~$150/month, SLA-backed (99.95%), up to 2 units, API cache. Best for: small production workloads with predictable traffic
- **Standard**: ~$750/month, VNet injection, SLA-backed (99.95%), up to 4 units. Best for: medium production workloads requiring VNet integration
- **Premium**: ~$3,000+/month per unit, VNet injection, multi-region, availability zones, 99.99% SLA. Best for: enterprise production, global distribution, high availability

**Production - v2 Tiers** (2024+, consumption-based auto-scaling):
- **Basic v2**: Consumption-based pricing (~$0.125/hour + per-call charges), 99.95% SLA, auto-scaling (0-10 compute units), fast provisioning (5-15 min). Best for: cost-optimized production workloads with variable traffic, no VNet requirements
- **Standard v2**: Consumption-based pricing (~$0.25/hour + per-call charges), 99.95% SLA, VNet injection, availability zone support, auto-scaling (0-100 units), fast provisioning (5-15 min). Best for: enterprise workloads requiring VNet, zone redundancy, and elastic scale

### v2 Tier Advantages (Introduced 2024-2025)

The v2 tiers represent a significant modernization of Azure APIM:
- **Fast Provisioning**: 5-15 minutes vs 30-45 minutes for classic tiers
- **Auto-Scaling**: Automatically scale based on demand without manual intervention
- **Cost Efficiency**: Pay only for what you use with consumption-based pricing
- **Zone Redundancy**: Built-in availability zone support in Standard v2 for 99.99% uptime (when configured across zones)
- **No Upgrade Path Needed**: Deploy fresh instances quickly when scaling requirements change

💡 **Cost Optimization Tips**:
- Use **Consumption** or **Developer** tier for learning and development—delete resources when not in use
- Consider **v2 tiers** for production workloads with variable traffic patterns to benefit from auto-scaling and consumption pricing
- Use **Basic v2** for production APIs that don't require VNet integration—significant cost savings vs classic tiers
- Use **Standard v2** for enterprise production workloads requiring VNet and zone redundancy
- Leverage **caching policies** to reduce backend calls and associated costs
- Monitor usage with Azure Monitor to optimize tier selection

📊 **Pricing Reference**: See [docs/tiers-and-skus.md](docs/tiers-and-skus.md) for detailed tier comparisons and [Azure APIM Pricing](https://azure.microsoft.com/pricing/details/api-management/) for official current pricing.

## 🔐 Security Best Practices

- ✅ Use **Managed Identity** for Azure service connections
- ✅ Store secrets in **Azure Key Vault**, reference via Named Values
- ✅ Implement **JWT validation** for OAuth/OIDC flows
- ✅ Use **subscription keys** for API access control
- ✅ Enable **diagnostic logging** to Log Analytics
- ✅ Apply **IP filtering** for backend protection
- ✅ Consider **private endpoints** for internal APIs

## 🎨 Frontend Integration Examples

### [React Sample](frontend-samples/react-sample/)
Modern React app with Vite, TypeScript, and Fetch API integration.

```bash
cd frontend-samples/react-sample
npm install && npm run dev
```

### [Angular Sample](frontend-samples/angular-sample/)
Angular 17 app with HttpClient service and RxJS Observables.

```bash
cd frontend-samples/angular-sample
npm install && npm start
```

**Learn more**: See [frontend-samples/README.md](frontend-samples/README.md)

## 🔌 Third-Party API Integrations

### [Twilio SMS](src/third-party-integrations/twilio-sms/)
Send SMS messages with Twilio API, includes Azure Key Vault integration.

```bash
cd src/third-party-integrations/twilio-sms
npm install && npm start
```

### [Stripe Payments](src/third-party-integrations/stripe-payment/)
Process secure payments with Stripe's Payment Intents API.

```bash
cd src/third-party-integrations/stripe-payment
npm install && npm start
```

**Learn more**: See [src/third-party-integrations/README.md](src/third-party-integrations/README.md)

## 🐳 Containerization

### Docker Support
Azure Functions can be containerized for consistent deployments:

```bash
cd src/functions-sample
docker build -t azure-function-sample:latest .
docker run -p 8080:80 azure-function-sample:latest
```

### Kubernetes Deployment
Production-ready Kubernetes manifests with best practices:

```bash
cd src/functions-sample/k8s
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

**Learn more**: See [src/functions-sample/k8s/README.md](src/functions-sample/k8s/README.md)

## 🧪 Testing

```bash
# Run Postman tests with Newman
cd tests/postman
newman run collection.json -e environment.json

# Run REST Client tests (VS Code)
# Open tests/rest-client/sample.http and click "Send Request"

# Run k6 load tests
cd tests/k6
k6 run load-test.js

# Run frontend tests
cd frontend-samples/react-sample
npm test

# Run integration tests
cd src/third-party-integrations/twilio-sms
npm test
```

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for:
- Code of conduct
- Pull request process
- Coding standards
- Testing requirements

## 📖 Documentation

Detailed documentation is available in the [docs/](docs/) directory:

### Core Guides
- [Core Concepts](docs/concepts.md) - APIM fundamentals and architecture
- [Networking Guide](docs/networking.md) - VNet integration, private endpoints
- [Security Guide](docs/security.md) - Authentication, authorization, Key Vault
- [SKU Comparison](docs/tiers-and-skus.md) - Pricing tiers and cost guidance
- [Observability](docs/observability.md) - Monitoring, logging, dashboards
- [Troubleshooting](docs/troubleshooting.md) - Common issues and solutions

### Advanced Topics
- [API Center Integration](docs/api-center.md) - API governance and catalog
- [Front Door + APIM](docs/front-door.md) - Global distribution patterns
- [AI Gateway](docs/ai-gateway.md) - Azure OpenAI integration

### Migration
- [AWS API Gateway to APIM Migration](docs/migration/aws-to-apim.md) - AWS migration guide
- [Google API to APIM Migration](docs/migration/google-to-apim.md) - Google migration guide
- [Migration Tools](tools/migration/) - Scripts and utilities

### Integration Examples
- [Frontend Samples](frontend-samples/) - React and Angular integration examples
- [Third-Party APIs](src/third-party-integrations/) - Twilio SMS and Stripe payments
- [Container Deployment](src/functions-sample/k8s/) - Docker and Kubernetes guides

## 🔗 Useful Links

- [Official APIM Documentation](https://learn.microsoft.com/azure/api-management/)
- [APIM Policy Reference](https://learn.microsoft.com/azure/api-management/api-management-policies)
- [APIM Pricing](https://azure.microsoft.com/pricing/details/api-management/)
- [Azure Architecture Center](https://learn.microsoft.com/azure/architecture/reference-architectures/apis/)

## 📝 License

This project is licensed under the terms specified in [LICENSE](LICENSE).

## ⚠️ Disclaimer

**Educational Use Only**: This repository is provided for educational and demonstration purposes. While the templates and examples follow Azure best practices, they must be thoroughly reviewed, tested, and customized for production use according to your organization's specific requirements, security policies, and compliance needs.

**Pricing and Features**: Azure API Management pricing, features, and tier availability are subject to change. The pricing estimates and tier comparisons in this repository are indicative and based on US East region as of early 2026. Always consult the official [Azure Pricing page](https://azure.microsoft.com/pricing/details/api-management/) and [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) for current, region-specific pricing before making deployment decisions.

**Validation Required**: All infrastructure templates, policies, and configurations should be validated in a non-production environment before deployment to production. Cloud services evolve rapidly—verify that features and approaches documented here are current and suitable for your use case.

---

**Happy Learning!** 🎓 If you find this repository helpful, please give it a ⭐