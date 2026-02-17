# APIM Module Variables

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "apim_name" {
  type = string
}

variable "apim_sku" {
  type        = string
  description = "APIM SKU tier. Supported values: Consumption, Developer, Basic, Standard, Premium, BasicV2, StandardV2"
  validation {
    condition     = contains(["Consumption", "Developer", "Basic", "Standard", "Premium", "BasicV2", "StandardV2"], var.apim_sku)
    error_message = "APIM SKU must be one of: Consumption, Developer, Basic, Standard, Premium, BasicV2, StandardV2"
  }
}

variable "apim_capacity" {
  type = number
}

variable "publisher_email" {
  type = string
}

variable "publisher_name" {
  type = string
}

variable "vnet_type" {
  type    = string
  default = "None"
}

variable "subnet_id" {
  type    = string
  default = null
}

variable "enable_custom_domain" {
  type    = bool
  default = false
}

variable "custom_domain_hostname" {
  type    = string
  default = ""
}

variable "key_vault_id" {
  type    = string
  default = ""
}

variable "certificate_secret_name" {
  type    = string
  default = ""
}

variable "app_insights_id" {
  type    = string
  default = null
}

variable "app_insights_instrumentation_key" {
  type      = string
  default   = null
  sensitive = true
}

variable "log_analytics_workspace_id" {
  type    = string
  default = null
}

variable "tags" {
  type = map(string)
}

variable "workspaces" {
  type = map(object({
    display_name = string
    description  = string
  }))
  description = "Map of workspace configurations. Key is workspace name, value contains display_name and description"
  default     = {}
}
