# Terraform Outputs

output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.main.name
}

output "apim_id" {
  description = "APIM resource ID"
  value       = module.apim.apim_id
}

output "apim_gateway_url" {
  description = "APIM gateway URL"
  value       = module.apim.gateway_url
}

output "apim_management_url" {
  description = "APIM management API URL"
  value       = module.apim.management_url
}

output "apim_portal_url" {
  description = "APIM developer portal URL"
  value       = module.apim.portal_url
}

output "apim_principal_id" {
  description = "APIM managed identity principal ID"
  value       = module.apim.principal_id
}

output "app_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = var.enable_diagnostics ? module.diagnostics[0].app_insights_instrumentation_key : null
  sensitive   = true
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  value       = var.enable_diagnostics ? module.diagnostics[0].log_analytics_workspace_id : null
}

output "vnet_id" {
  description = "VNet resource ID"
  value       = var.enable_vnet ? module.network[0].vnet_id : null
}

output "subnet_id" {
  description = "Subnet resource ID"
  value       = var.enable_vnet ? module.network[0].subnet_id : null
}
