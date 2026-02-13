# Network Module Outputs
output "vnet_id" { value = azurerm_virtual_network.main.id }
output "subnet_id" { value = azurerm_subnet.apim.id }
output "nsg_id" { value = azurerm_network_security_group.apim.id }
