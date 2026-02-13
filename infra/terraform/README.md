# Terraform Infrastructure

This directory contains Terraform configuration for deploying Azure API Management infrastructure.

## Structure

```
terraform/
├── main.tf                      # Main orchestration
├── variables.tf                 # Input variables
├── outputs.tf                   # Output values
├── public-dev.tfvars           # Public dev environment
├── internal.tfvars             # Internal VNet environment
└── modules/
    ├── apim/                   # APIM module
    ├── network/                # VNet, Subnet, NSG
    └── diagnostics/            # App Insights, Log Analytics
```

## Quick Start

### Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.5.0
- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)
- Azure subscription with Contributor access

### Deploy Public Development Instance

```bash
# Login to Azure
az login
az account set --subscription "<your-subscription-id>"

# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var-file="public-dev.tfvars"

# Apply configuration
terraform apply -var-file="public-dev.tfvars"
```

### Deploy Internal (VNet) Instance

```bash
terraform init
terraform plan -var-file="internal.tfvars"
terraform apply -var-file="internal.tfvars"
```

### Custom Deployment

```bash
terraform apply \
  -var="environment=dev" \
  -var="base_name=myapi" \
  -var="apim_sku=Developer" \
  -var="publisher_email=admin@example.com" \
  -var="publisher_name=My Org"
```

## Backend Configuration

**Local Backend (Default):**
State file is stored locally (not recommended for teams).

**Remote Backend (Recommended for Production):**

Uncomment the backend configuration in `main.tf`:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstate"
    container_name       = "tfstate"
    key                  = "apim.terraform.tfstate"
  }
}
```

Then initialize:

```bash
terraform init -migrate-state
```

## Variables

See `variables.tf` for full list. Key variables:

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `publisher_email` | Yes | - | APIM publisher email |
| `publisher_name` | Yes | - | Organization name |
| `environment` | No | `dev` | Environment (dev/staging/prod) |
| `apim_sku` | No | `Developer` | APIM SKU tier |
| `enable_vnet` | No | `false` | Enable VNet integration |
| `enable_diagnostics` | No | `true` | Enable monitoring |

## Outputs

After deployment:

```bash
# View all outputs
terraform output

# Get specific output
terraform output apim_gateway_url

# Get sensitive output (e.g., App Insights key)
terraform output -raw app_insights_instrumentation_key
```

## Managing State

```bash
# View state
terraform show

# List resources
terraform state list

# Remove resource from state (doesn't delete in Azure)
terraform state rm module.apim.azurerm_api_management.main

# Import existing resource
terraform import module.apim.azurerm_api_management.main /subscriptions/.../resourceGroups/.../providers/Microsoft.ApiManagement/service/apim-name
```

## Validation

```bash
# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Plan with detailed output
terraform plan -var-file="public-dev.tfvars" -out=tfplan

# Show plan
terraform show tfplan
```

## Destroy Resources

```bash
# Plan destroy
terraform plan -destroy -var-file="public-dev.tfvars"

# Destroy all resources
terraform destroy -var-file="public-dev.tfvars"
```

## Modules

### APIM Module (`modules/apim/`)

Deploys:
- API Management instance
- System-assigned Managed Identity
- Application Insights logger
- Diagnostic settings
- Named values

### Network Module (`modules/network/`)

Deploys (when `enable_vnet = true`):
- Virtual Network
- Subnet for APIM
- Network Security Group with required rules
- Service endpoints

### Diagnostics Module (`modules/diagnostics/`)

Deploys (when `enable_diagnostics = true`):
- Log Analytics workspace
- Application Insights

## Cost Estimation

```bash
# Install Infracost
brew install infracost  # macOS
# or download from https://www.infracost.io/

# Generate cost estimate
infracost breakdown --path .

# Compare costs between configurations
infracost diff --path . --compare-to baseline.json
```

**Example Monthly Costs (East US):**
- Developer: ~$50
- Application Insights: ~$10-50
- Log Analytics: ~$5-20
- **Total**: ~$65-120/month

## Troubleshooting

### Issue: Provider version mismatch

```bash
terraform init -upgrade
```

### Issue: State locked

```bash
# Force unlock (use with caution)
terraform force-unlock <lock-id>
```

### Issue: VNet deployment fails

- Ensure subnet is empty
- Check NSG rules
- Verify subnet is /27 or larger

### Debug Mode

```bash
export TF_LOG=DEBUG
terraform apply -var-file="public-dev.tfvars"
```

## Best Practices

1. **Use remote backend** for team collaboration
2. **Store tfvars in version control** (except secrets)
3. **Use workspaces** for multiple environments
4. **Pin provider versions** for reproducibility
5. **Use modules** for reusability
6. **Run `terraform plan`** before apply
7. **Enable state locking** with remote backend
8. **Use `-out` flag** to review plans before applying
9. **Tag all resources** for cost tracking
10. **Document custom configurations**

## CI/CD Integration

See `.github/workflows/infra-deploy.yml` for GitHub Actions example.

## Additional Resources

- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [APIM Resource](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

## Next Steps

- [Deployment scripts](../../scripts/) for automation
- [Bicep templates](../bicep/) for alternative IaC
- [Documentation](../../docs/) for architecture guidance

---

**Happy Terraforming!** For issues, see [troubleshooting guide](../../docs/troubleshooting.md).
