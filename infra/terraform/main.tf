# Terraform Configuration for Azure API Management
# Main orchestration file

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.75"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 1.9"
    }
  }
  
  # TODO: Configure remote backend for production
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "sttfstate"
  #   container_name       = "tfstate"
  #   key                  = "apim.terraform.tfstate"
  # }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
}

provider "azapi" {}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.base_name}-${var.environment}"
  location = var.location
  tags     = var.tags
}

# Diagnostics Module (Application Insights + Log Analytics)
module "diagnostics" {
  source = "./modules/diagnostics"
  count  = var.enable_diagnostics ? 1 : 0

  resource_group_name  = azurerm_resource_group.main.name
  location             = azurerm_resource_group.main.location
  base_name            = var.base_name
  environment          = var.environment
  retention_in_days    = var.log_retention_days
  tags                 = var.tags
}

# Network Module (VNet, Subnet, NSG)
module "network" {
  source = "./modules/network"
  count  = var.enable_vnet ? 1 : 0

  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  base_name             = var.base_name
  environment           = var.environment
  vnet_type             = var.vnet_type
  vnet_address_space    = var.vnet_address_space
  subnet_address_prefix = var.subnet_address_prefix
  tags                  = var.tags
}

# API Management Module
module "apim" {
  source = "./modules/apim"

  resource_group_name            = azurerm_resource_group.main.name
  location                       = azurerm_resource_group.main.location
  apim_name                      = "${var.base_name}-${var.environment}"
  apim_sku                       = var.apim_sku
  apim_capacity                  = var.apim_capacity
  publisher_email                = var.publisher_email
  publisher_name                 = var.publisher_name
  vnet_type                      = var.enable_vnet ? var.vnet_type : "None"
  subnet_id                      = var.enable_vnet ? module.network[0].subnet_id : null
  enable_custom_domain           = var.enable_custom_domain
  custom_domain_hostname         = var.custom_domain_hostname
  key_vault_id                   = var.key_vault_id
  certificate_secret_name        = var.certificate_secret_name
  app_insights_id                = var.enable_diagnostics ? module.diagnostics[0].app_insights_id : null
  app_insights_instrumentation_key = var.enable_diagnostics ? module.diagnostics[0].app_insights_instrumentation_key : null
  log_analytics_workspace_id     = var.enable_diagnostics ? module.diagnostics[0].log_analytics_workspace_id : null
  tags                           = var.tags

  depends_on = [
    module.network,
    module.diagnostics
  ]
}
