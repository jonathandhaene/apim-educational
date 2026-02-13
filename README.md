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
│   ├── api-center.md         # Azure API Center integration
│   ├── front-door.md         # Front Door + APIM patterns
│   ├── ai-gateway.md         # AI Gateway capabilities
│   ├── migration/            # Migration guides
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
│   └── lab-05-ops-architecture/ # Operations and best practices
├── src/                       # Sample applications
│   └── functions-sample/     # Azure Function example
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
    └── migration/            # Google API to APIM migration helpers
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

**[📚 View All Labs](labs/README.md)** - Five progressive labs covering:
1. **[Lab 1: Beginner](labs/lab-01-beginner/README.md)** - Deploy APIM, import API, basic policies
2. **[Lab 2: Intermediate](labs/lab-02-intermediate/README.md)** - Diagnostics, JWT, load testing
3. **[Lab 3: Advanced](labs/lab-03-advanced/README.md)** - VNet, private endpoints, Key Vault
4. **[Lab 4: Expert](labs/lab-04-expert/README.md)** - Self-hosted gateway, Front Door, blue/green
5. **[Lab 5: Operations](labs/lab-05-ops-architecture/README.md)** - API Center, AI Gateway, best practices

Or jump right in:
1. **Navigate to labs**: `cd labs/lab-01-beginner/`
2. **Follow the README**: Step-by-step instructions included
3. **Import sample API**: Use provided OpenAPI definition
4. **Test with Postman**: Collection ready in `tests/postman/`

## 📚 Learning Path

Our structured learning path takes you from beginner to expert through five comprehensive labs. Each lab builds on concepts from previous ones:

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

> **Note**: Pricing is indicative and based on US regions as of 2026. Actual costs vary by region, usage patterns, and Azure subscription type. Always use the [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) for accurate estimates.

**Development/Learning** (lowest cost):
- **Consumption tier**: Pay-per-execution, no upfront cost (~$3.50 per million calls)
- **Developer tier**: ~$50/month, includes all features except SLA

**Production - Classic Tiers**:
- **Basic**: ~$150/month, SLA-backed (99.95%), limited scale
- **Standard**: ~$750/month, VNet injection, SLA-backed (99.95%)
- **Premium**: ~$3,000+/month, VNet injection, multi-region, high availability (99.99% SLA)

**Production - v2 Tiers** (2026+, consumption-based pricing):
- **Basic v2**: Consumption-based, SLA-backed (99.95%), auto-scaling, cost-optimized for predictable workloads
- **Standard v2**: Consumption-based, SLA-backed (99.95%), VNet injection, zone redundancy, optimized for enterprise workloads

💡 **Tip**: Use Consumption or Developer tier for learning. Delete resources when not in use. v2 tiers offer consumption-based pricing that can be more cost-effective for variable workloads.

## 🔐 Security Best Practices

- ✅ Use **Managed Identity** for Azure service connections
- ✅ Store secrets in **Azure Key Vault**, reference via Named Values
- ✅ Implement **JWT validation** for OAuth/OIDC flows
- ✅ Use **subscription keys** for API access control
- ✅ Enable **diagnostic logging** to Log Analytics
- ✅ Apply **IP filtering** for backend protection
- ✅ Consider **private endpoints** for internal APIs

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
- [**Google API to APIM Migration**](docs/migration/google-to-apim.md) - Complete migration guide
- [Migration Tools](tools/migration/) - Scripts and utilities

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