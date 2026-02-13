# APIM Module Outputs

output "apim_id" {
  value = azurerm_api_management.main.id
}

output "gateway_url" {
  value = azurerm_api_management.main.gateway_url
}

output "management_url" {
  value = azurerm_api_management.main.management_api_url
}

output "portal_url" {
  value = azurerm_api_management.main.portal_url
}

output "principal_id" {
  value = azurerm_api_management.main.identity[0].principal_id
}

output "private_ip_addresses" {
  value = azurerm_api_management.main.private_ip_addresses
}
