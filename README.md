# APIM Educational Repository

Welcome to the APIM Educational Repository! This repository is designed to help developers and learners understand Azure API Management (APIM) through comprehensive documentation, practical examples, hands-on labs, and migration tooling.

> **⚠️ Educational Disclaimer**: All resources are intended for learning and skill development. Pricing estimates are indicative and based on 2026 rates in US regions. Always verify current pricing in your region using the [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) and validate all configurations before production deployment. Cloud features and best practices evolve—consult the [official Azure API Management documentation](https://learn.microsoft.com/azure/api-management/) for the latest guidance.

## 📖 Purpose

This repository is a structured learning resource covering the full spectrum of Azure API Management: from deploying your first gateway to advanced security, networking, AI integration, observability, and multi-environment workspace management. It also provides ready-to-use tooling for migrating APIs from Google (Apigee / Cloud API Gateway) and AWS API Gateway to Azure APIM.

## 🗂️ Repository Structure

| Directory | Contents |
|-----------|----------|
| [`labs/`](labs/) | Six hands-on labs from beginner to expert |
| [`docs/`](docs/) | Conceptual guides: security, networking, observability, tiers, migration |
| [`infra/`](infra/) | Infrastructure-as-code templates (Bicep and Terraform) |
| [`policies/`](policies/) | Reusable APIM policy XML fragments |
| [`tools/migration/`](tools/migration/) | OpenAPI translation scripts and Python library for API migration |
| [`scripts/`](scripts/) | Azure CLI automation scripts (deploy, import, sync) |
| [`tests/`](tests/) | Postman collections, REST Client files, and k6 load tests |
| [`frontend-samples/`](frontend-samples/) | React and Angular front-end integration samples |
| [`src/`](src/) | Azure Functions samples and third-party integrations |

## 🚀 Run Your First Lab

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

See the [Labs README](labs/README.md) for full prerequisites and cost management tips.

## 🎓 Learning Path

| Lab | Level | Duration | Focus Areas |
|-----|-------|----------|-------------|
| [Lab 1: Beginner](labs/lab-01-beginner/README.md) | Beginner | 45–60 min | Deploy APIM, import API, basic policies, testing |
| [Lab 2: Intermediate](labs/lab-02-intermediate/README.md) | Intermediate | 60–90 min | Diagnostics, JWT validation, rate limiting, load testing |
| [Lab 3: Advanced](labs/lab-03-advanced/README.md) | Advanced | 90–120 min | VNet integration, private endpoints, Key Vault, revisions |
| [Lab 4: Expert](labs/lab-04-expert/README.md) | Expert | 120–150 min | Self-hosted gateway, Front Door, blue/green deployment, caching |
| [Lab 5: Operations & Architecture](labs/lab-05-ops-architecture/README.md) | Architecture | 90–120 min | API Center, AI Gateway, observability, DR, best practices |
| [Lab 6: Workspaces](labs/lab-06-workspaces/README.md) | Intermediate | 60–90 min | Multi-environment management, workspace segmentation, collaboration |

## 🔧 Associated Tools

### Migration Scripts

Located in [`tools/migration/`](tools/migration/), these tools automate OpenAPI spec translation from third-party gateways to Azure APIM:

| Tool | Purpose |
|------|---------|
| `openapi_utils.py` | Core Python library: Swagger 2.0→OpenAPI 3.0 conversion, `operationId` generation, APIM validation, vendor extension removal |
| `translate-openapi.sh` / `translate-openapi.ps1` | Shell/PowerShell wrappers for Google Apigee and Cloud API Gateway specs (removes `x-google-*` extensions) |
| `translate-openapi-aws.sh` / `translate-openapi-aws.ps1` | Shell/PowerShell wrappers for AWS API Gateway specs (removes `x-amazon-*` extensions) |

**Quick usage:**
```bash
# Google / Apigee spec
cd tools/migration
./translate-openapi.sh google-api.yaml apim-api.yaml

# AWS API Gateway spec
./translate-openapi-aws.sh aws-export.yaml apim-api.yaml
```

See the [Migration Tools README](tools/migration/README.md) for full workflow and prerequisites.

### Deployment & Import Scripts

Located in [`scripts/`](scripts/):

- `deploy-apim.sh` / `deploy-apim.ps1` — Deploy an APIM instance via Azure CLI
- `import-openapi.sh` / `import-openapi.ps1` — Import an OpenAPI spec into APIM
- `sync-api-center.sh` / `sync-api-center.ps1` — Synchronize APIs with Azure API Center

## 🌐 Migration Resources

Comprehensive step-by-step guides for migrating to Azure APIM:

| Source Platform | Guide |
|-----------------|-------|
| Google Apigee / Cloud API Gateway | [Google to Azure APIM Migration Guide](docs/migration/google-to-apim.md) |
| AWS API Gateway (REST & HTTP) | [AWS to Azure APIM Migration Guide](docs/migration/aws-to-apim.md) |

Both guides cover assessment, feature mapping, policy translation, tooling, testing, and cutover strategies.

## 🔗 Integration Examples

- **Front-End Integration**: [React sample](frontend-samples/react-sample/) and [Angular sample](frontend-samples/angular-sample/) demonstrating APIM-backed API calls
- **Third-Party Services**: [Twilio SMS integration](src/third-party-integrations/twilio-sms/) via Azure Functions and APIM
- **AI Gateway**: APIM as a gateway for Azure OpenAI—see [AI Gateway docs](docs/ai-gateway.md) and [`policies/ai-gateway.xml`](policies/ai-gateway.xml)

## 📚 Documentation

| Guide | Topics |
|-------|--------|
| [Core Concepts](docs/concepts.md) | Gateway architecture, products, subscriptions, policies |
| [Tiers and SKUs](docs/tiers-and-skus.md) | Consumption, Developer, Basic/Standard v2, Premium tiers |
| [Security](docs/security.md) | JWT, OAuth, mTLS, Key Vault, managed identity |
| [Networking](docs/networking.md) | VNet integration, private endpoints, Front Door |
| [Observability](docs/observability.md) | Application Insights, Log Analytics, KQL queries |
| [Workspaces](docs/workspaces.md) | Multi-environment segmentation, workspace policies |
| [API Center](docs/api-center.md) | API governance and catalog synchronization |
| [AI Gateway](docs/ai-gateway.md) | Azure OpenAI load balancing, token limits, semantic caching |
| [Troubleshooting](docs/troubleshooting.md) | Common issues and resolutions |

## 🏗️ Infrastructure Templates

Reusable IaC templates for deploying APIM and related resources:

- **Bicep**: [`infra/bicep/`](infra/bicep/) — modules for APIM, workspaces, networking
- **Terraform**: [`infra/terraform/`](infra/terraform/) — modules for APIM, workspaces, Key Vault

Example parameter files for workspace deployments:
- `infra/bicep/params/workspaces-demo.bicepparam`
- `infra/terraform/workspaces-demo.tfvars`

## 🤝 Contributing

We welcome contributions! Please read the [Contribution Guidelines](CONTRIBUTING.md) for details on how to get involved, open an [Issue](https://github.com/jonathandhaene/apim-educational/issues), or submit a [Pull Request](https://github.com/jonathandhaene/apim-educational/pulls).

---

**Happy Learning!** 🚀 If you find this repository helpful, please give it a ⭐