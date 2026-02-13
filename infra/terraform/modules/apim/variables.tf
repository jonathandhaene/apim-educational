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
  type = string
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
  type = string
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
