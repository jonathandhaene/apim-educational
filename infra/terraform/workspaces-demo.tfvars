# Terraform tfvars for development environment with workspaces

environment   = "dev"
base_name     = "apim-workspaces-demo"
location      = "eastus"
apim_sku      = "Developer"
apim_capacity = 1

# TODO: Replace with your information
publisher_email = "admin@example.com"
publisher_name  = "Educational Organization"

# Networking
enable_vnet           = false
vnet_type             = "None"
vnet_address_space    = ["10.0.0.0/16"]
subnet_address_prefix = "10.0.1.0/24"

# Custom Domain (disabled by default)
enable_custom_domain    = false
custom_domain_hostname  = ""
key_vault_id            = ""
certificate_secret_name = ""

# Diagnostics
enable_diagnostics = true
log_retention_days = 30

# Workspaces - Multi-environment configuration
workspaces = {
  dev = {
    display_name = "Development Workspace"
    description  = "Workspace for development and experimentation"
  }
  test = {
    display_name = "Testing Workspace"
    description  = "Workspace for QA and integration testing"
  }
  prod = {
    display_name = "Production Workspace"
    description  = "Workspace for production APIs"
  }
}

# Tags
tags = {
  Environment = "dev"
  ManagedBy   = "Terraform"
  Purpose     = "Educational"
  Feature     = "Workspaces"
}
