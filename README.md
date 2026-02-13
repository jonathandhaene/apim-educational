# Azure API Management Educational Repository

Welcome to the Azure API Management (APIM) Educational Repository! This comprehensive learning resource provides hands-on labs, infrastructure templates, policy examples, and best practices for working with Azure API Management.

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
│   └── diagrams/             # Architecture diagrams
├── infra/                     # Infrastructure as Code
│   ├── bicep/                # Modular Bicep templates
│   └── terraform/            # Terraform modules
├── labs/                      # Hands-on guided labs
│   └── beginner/             # Starter labs
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
└── scripts/                   # Automation scripts
    ├── deploy-apim.ps1/.sh   # Deployment scripts
    ├── import-openapi.ps1/.sh # API import automation
    └── sync-api-center.ps1/.sh # API Center sync
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

1. **Navigate to labs**: `cd labs/beginner/01-getting-started/`
2. **Follow the README**: Step-by-step instructions included
3. **Import sample API**: Use provided OpenAPI definition
4. **Test with Postman**: Collection ready in `tests/postman/`

## 📚 Learning Path

### Beginner
1. Deploy your first APIM instance (Consumption tier)
2. Import the sample API using OpenAPI
3. Apply basic policies (rate limiting, caching)
4. Test with Postman or REST Client
5. View logs in Application Insights

### Intermediate
- Configure virtual network integration
- Implement JWT validation and OAuth
- Set up custom domains with certificates
- Deploy self-hosted gateway
- Implement API versioning and revisions

### Advanced
- Multi-region deployment patterns
- Front Door + APIM integration
- Private endpoint configuration
- AI Gateway for LLM APIs
- Azure API Center synchronization

## 💰 Cost Considerations

**Development/Learning** (lowest cost):
- **Consumption tier**: Pay-per-execution, no upfront cost
- **Developer tier**: ~$50/month, includes all features except SLA

**Production** (higher cost):
- **Basic**: ~$150/month, SLA-backed
- **Standard**: ~$750/month, multi-region
- **Premium**: ~$3000+/month, VNet injection, multi-region, high availability

💡 **Tip**: Use Consumption tier for learning, delete resources when not in use

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
- [Core Concepts](docs/concepts.md)
- [Networking Guide](docs/networking.md)
- [Security Guide](docs/security.md)
- [SKU Comparison](docs/tiers-and-skus.md)
- [Observability](docs/observability.md)
- [Troubleshooting](docs/troubleshooting.md)

### 🔄 Migration Guides

Migrating from another API gateway platform? We've got you covered:
- [AWS API Gateway → Azure APIM](docs/migration/aws-to-apim.md) - Comprehensive guide for migrating from Amazon API Gateway (REST/HTTP APIs)
- **Google Cloud API Gateway** - Coming soon!

Migration tools available in [tools/migration/](tools/migration/).

## 🔗 Useful Links

- [Official APIM Documentation](https://learn.microsoft.com/azure/api-management/)
- [APIM Policy Reference](https://learn.microsoft.com/azure/api-management/api-management-policies)
- [APIM Pricing](https://azure.microsoft.com/pricing/details/api-management/)
- [Azure Architecture Center](https://learn.microsoft.com/azure/architecture/reference-architectures/apis/)

## 📝 License

This project is licensed under the terms specified in [LICENSE](LICENSE).

## ⚠️ Disclaimer

This repository is for educational purposes. The templates and examples demonstrate capabilities but should be reviewed and customized for production use according to your organization's requirements and security policies.

---

**Happy Learning!** 🎓 If you find this repository helpful, please give it a ⭐