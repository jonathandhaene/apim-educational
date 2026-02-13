# Terraform Variables

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "base_name" {
  description = "Base name for resources"
  type        = string
  default     = "apim"
}

variable "apim_sku" {
  description = "APIM SKU name (includes v2 tiers: BasicV2, StandardV2 for consumption-based pricing)"
  type        = string
  default     = "Developer"
  validation {
    condition     = contains(["Consumption", "Developer", "Basic", "Standard", "Premium", "BasicV2", "StandardV2"], var.apim_sku)
    error_message = "APIM SKU must be one of: Consumption, Developer, Basic, Standard, Premium, BasicV2, StandardV2."
  }
}

variable "apim_capacity" {
  description = "APIM capacity (number of units)"
  type        = number
  default     = 1
  validation {
    condition     = var.apim_capacity >= 0 && var.apim_capacity <= 12
    error_message = "APIM capacity must be between 0 and 12."
  }
}

variable "publisher_email" {
  description = "Publisher email for APIM"
  type        = string
}

variable "publisher_name" {
  description = "Publisher organization name"
  type        = string
}

variable "enable_vnet" {
  description = "Enable VNet integration"
  type        = bool
  default     = false
}

variable "vnet_type" {
  description = "VNet integration type"
  type        = string
  default     = "None"
  validation {
    condition     = contains(["None", "External", "Internal"], var.vnet_type)
    error_message = "VNet type must be None, External, or Internal."
  }
}

variable "vnet_address_space" {
  description = "VNet address space"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefix" {
  description = "Subnet address prefix for APIM"
  type        = string
  default     = "10.0.1.0/24"
}

variable "enable_custom_domain" {
  description = "Enable custom domain configuration"
  type        = bool
  default     = false
}

variable "custom_domain_hostname" {
  description = "Custom domain hostname (e.g., api.contoso.com)"
  type        = string
  default     = ""
}

variable "key_vault_id" {
  description = "Key Vault resource ID for certificates"
  type        = string
  default     = ""
}

variable "certificate_secret_name" {
  description = "Certificate secret name in Key Vault"
  type        = string
  default     = ""
}

variable "enable_diagnostics" {
  description = "Enable Application Insights and Log Analytics"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 30
  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "Log retention must be between 30 and 730 days."
  }
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Purpose   = "Educational"
  }
}
