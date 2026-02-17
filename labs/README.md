# Azure API Management Labs

Welcome to the hands-on labs for Azure API Management! This learning path takes you from beginner to expert through six progressive labs, each building upon the previous one.

> **⚠️ Educational Disclaimer**: These labs are designed for learning and skill development. Pricing estimates are indicative and based on 2026 rates in US regions. Always verify current pricing in your region using the [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) and validate all configurations before production deployment. Cloud features and best practices evolve—consult [official Azure API Management documentation](https://learn.microsoft.com/azure/api-management/) for the latest guidance.

## 🎯 Learning Path Overview

| Lab | Level | Duration | Focus Areas |
|-----|-------|----------|-------------|
| [Lab 1: Beginner](lab-01-beginner/README.md) | Beginner | 45-60 min | Deploy APIM, import API, basic policies, testing |
| [Lab 2: Intermediate](lab-02-intermediate/README.md) | Intermediate | 60-90 min | Diagnostics, JWT validation, rate limiting, load testing |
| [Lab 3: Advanced](lab-03-advanced/README.md) | Advanced | 90-120 min | VNet integration, private endpoints, Key Vault, revisions |
| [Lab 4: Expert](lab-04-expert/README.md) | Expert | 120-150 min | Self-hosted gateway, Front Door, blue/green deployment, caching |
| [Lab 5: Operations & Architecture](lab-05-ops-architecture/README.md) | Architecture | 90-120 min | API Center, AI Gateway, observability, DR, best practices |
| [Lab 6: Workspaces](lab-06-workspaces/README.md) | Intermediate | 60-90 min | Multi-environment management, workspace segmentation, collaboration |

## 📋 Prerequisites

### Required for All Labs
- **Azure Subscription**: [Get a free account](https://azure.microsoft.com/free/)
- **Azure CLI**: [Installation guide](https://docs.microsoft.com/cli/azure/install-azure-cli)
- **Git**: For cloning this repository
- **Text Editor**: VS Code recommended with REST Client extension

### Additional Tools (Lab-specific)
- **Postman**: For API testing (Labs 1-4)
- **k6**: For load testing (Lab 2+)
- **Docker**: For self-hosted gateway (Lab 4)
- **Kubectl**: For Kubernetes deployment (Lab 4)
- **PowerShell or Bash**: For running automation scripts

## 🚀 Getting Started

### Quick Start

```bash
# Clone the repository
git clone https://github.com/jonathandhaene/apim-educational.git
cd apim-educational

# Login to Azure
az login
az account set --subscription "<your-subscription-id>"

# Start with Lab 1
cd labs/lab-01-beginner
```

### Lab Progression

Each lab is designed to build on concepts from previous labs:

1. **Lab 1 (Beginner)**: Start here! Deploy your first APIM instance, import a sample API, apply basic policies (rate limiting, caching), and test with Postman or REST Client.

2. **Lab 2 (Intermediate)**: Add enterprise features - configure diagnostics with Application Insights and Log Analytics, implement JWT validation for authentication, apply advanced rate limiting policies, and run k6 load tests.

3. **Lab 3 (Advanced)**: Secure your deployment - configure VNet integration for private/internal mode, set up private endpoints, integrate Azure Key Vault for secrets management, and implement API versioning and revision strategies.

4. **Lab 4 (Expert)**: Deploy at scale - set up self-hosted gateway using Docker Compose and Kubernetes, integrate with Azure Front Door and WAF, implement blue/green deployments with revisions, and optimize performance with caching strategies.

5. **Lab 5 (Operations & Architecture)**: Production readiness - synchronize with Azure API Center, implement AI Gateway policies for LLM APIs, use observability with KQL queries, and review DR/cost optimization/best practices checklists.

6. **Lab 6 (Workspaces)**: Multi-environment management - configure APIM Workspaces for dev/test/prod environments, manage APIs within workspaces, implement workspace-specific policies, and establish promotion workflows for API deployment across environments.

## 💡 Learning Tips

### Time Management
- **Don't rush**: Each lab contains important concepts
- **Take breaks**: Complex labs can take 2+ hours
- **Checkpoint your work**: Use the validation steps to ensure you're on track

### Cost Management
- **Use Developer or Consumption tier** for learning (lowest cost)
- **Delete resources** when not actively using them
- **Set budget alerts** in Azure portal
- **Estimated costs**: 
  - Developer tier: ~$50/month (fixed cost)
  - Consumption tier: Pay-per-use (~$3.50 per million calls + gateway hours)
  - Basic v2 tier: Consumption-based, cost-effective for predictable workloads
  - Standard v2 tier: Consumption-based, optimized for enterprise workloads
- **Regional pricing varies**: Verify costs in your target Azure region

### Best Practices
- **Read before doing**: Review the entire lab before starting
- **Use provided scripts**: They're tested and save time
- **Keep notes**: Document any issues or insights
- **Ask questions**: Use GitHub Issues for help

## 🎓 What You'll Build

By completing all labs, you'll have hands-on experience with:

### Core APIM Features
- ✅ API gateway deployment and configuration
- ✅ API import using OpenAPI specifications
- ✅ Policy application (rate limiting, caching, transformation)
- ✅ Subscription and product management
- ✅ API versioning and revisions

### Security & Authentication
- ✅ JWT validation and OAuth integration
- ✅ Azure Key Vault integration for secrets
- ✅ Managed Identity for Azure service connections
- ✅ IP filtering and backend protection
- ✅ Private endpoint configuration

### Networking & Deployment
- ✅ Virtual Network integration (internal mode)
- ✅ Private endpoints for secure access
- ✅ Custom domains with certificates
- ✅ Self-hosted gateway on Docker and Kubernetes
- ✅ Multi-region deployment with Front Door

### Operations & Monitoring
- ✅ Application Insights integration
- ✅ Log Analytics workspace configuration
- ✅ Diagnostic logging setup
- ✅ KQL queries for observability
- ✅ Performance monitoring and optimization

### Environment Management
- ✅ APIM Workspaces for dev/test/prod segmentation
- ✅ Workspace-specific policies and configurations
- ✅ API promotion workflows across environments
- ✅ Multi-environment collaboration patterns

### Advanced Patterns
- ✅ AI Gateway for Azure OpenAI integration
- ✅ Azure API Center synchronization
- ✅ Blue/green deployment strategies
- ✅ Disaster recovery planning
- ✅ Cost optimization strategies

## 📚 Additional Resources

### Documentation
- [Core Concepts](../docs/concepts.md)
- [Security Guide](../docs/security.md)
- [Networking Guide](../docs/networking.md)
- [Observability](../docs/observability.md)
- [Workspaces Guide](../docs/workspaces.md)
- [Troubleshooting](../docs/troubleshooting.md)

### Infrastructure Templates
- [Bicep Templates](../infra/bicep/)
- [Terraform Modules](../infra/terraform/)

### Policy Examples
- [Policy Library](../policies/)
- [Rate Limiting](../policies/rate-limit.xml)
- [JWT Validation](../policies/jwt-validate.xml)
- [AI Gateway](../policies/ai-gateway.xml)

### Testing Resources
- [Postman Collections](../tests/postman/)
- [REST Client Files](../tests/rest-client/)
- [k6 Load Tests](../tests/k6/)

## 🔄 Migration Path

If you're migrating from Google's API services (Apigee or Cloud API Gateway) to Azure API Management, check out our comprehensive migration guide:

📖 [Google API to Azure APIM Migration Guide](../docs/migration/google-to-apim.md)

## 🤝 Contributing

Found an issue or have a suggestion? We welcome contributions!
- [Contribution Guidelines](../CONTRIBUTING.md)
- [Open an Issue](https://github.com/jonathandhaene/apim-educational/issues)
- [Submit a Pull Request](https://github.com/jonathandhaene/apim-educational/pulls)

## ⚠️ Important Notes

- **Provisioning time**: APIM instances take 30-45 minutes to deploy (classic tiers) or 5-15 minutes (v2 tiers)
- **Cleanup**: Remember to delete resources when done to avoid charges
- **Security**: Never commit secrets or API keys to version control
- **Testing**: Use test/dev subscriptions, not production accounts
- **Pricing**: Estimates provided are indicative; validate actual costs for your region and usage patterns

## 🎯 Next Steps

Ready to start learning? Head to [Lab 1: Beginner](lab-01-beginner/README.md) and deploy your first API Management instance!

---

**Happy Learning!** 🚀 If you find these labs helpful, please give this repository a ⭐
