# Terraform tfvars for internal (VNet-integrated) environment

environment    = "staging"
base_name      = "apim-educational"
location       = "eastus"
apim_sku       = "Developer"  # Use "Premium" for production
apim_capacity  = 1

# TODO: Replace with your information
publisher_email = "admin@example.com"
publisher_name  = "Educational Organization"

# Networking - Internal VNet mode
enable_vnet            = true
vnet_type              = "Internal"  # "Internal" for fully private, "External" for public gateway
vnet_address_space     = ["10.0.0.0/16"]
subnet_address_prefix  = "10.0.1.0/27"  # Larger subnet for production

# Custom Domain (configure if needed)
enable_custom_domain    = false
custom_domain_hostname  = "api-internal.contoso.com"
key_vault_id            = ""  # TODO: Add Key Vault resource ID
certificate_secret_name = ""  # TODO: Add certificate secret name

# Diagnostics
enable_diagnostics  = true
log_retention_days  = 90  # Longer retention for staging/prod

# Tags
tags = {
  Environment = "staging"
  ManagedBy   = "Terraform"
  Purpose     = "Educational"
  CostCenter  = "IT"
  NetworkType = "Internal"
}
