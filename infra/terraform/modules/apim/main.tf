# APIM Terraform Module
# Updated for 2026 best practices with v2 tier support

resource "azurerm_api_management" "main" {
  name                = var.apim_name
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email

  # SKU configuration
  # Note: v2 tiers (BasicV2, StandardV2) use auto-scaling; capacity is set to 0
  # Consumption tier also requires capacity 0
  sku_name = contains(["Consumption", "BasicV2", "StandardV2"], var.apim_sku) ? "${var.apim_sku}_0" : "${var.apim_sku}_${var.apim_capacity}"

  identity {
    type = "SystemAssigned"
  }

  virtual_network_type = var.vnet_type

  dynamic "virtual_network_configuration" {
    for_each = var.vnet_type != "None" && var.subnet_id != null ? [1] : []
    content {
      subnet_id = var.subnet_id
    }
  }

  dynamic "hostname_configuration" {
    for_each = var.enable_custom_domain && var.custom_domain_hostname != "" ? [1] : []
    content {
      proxy {
        host_name                    = var.custom_domain_hostname
        key_vault_id                 = "${var.key_vault_id}/secrets/${var.certificate_secret_name}"
        default_ssl_binding          = true
        negotiate_client_certificate = false
      }
    }
  }

  tags = var.tags
}

# Application Insights Logger
resource "azurerm_api_management_logger" "app_insights" {
  count               = var.app_insights_id != null ? 1 : 0
  name                = "app-insights-logger"
  api_management_name = azurerm_api_management.main.name
  resource_group_name = var.resource_group_name
  resource_id         = var.app_insights_id

  application_insights {
    instrumentation_key = var.app_insights_instrumentation_key
  }
}

# Global diagnostics
resource "azurerm_api_management_diagnostic" "global" {
  count                    = var.app_insights_id != null ? 1 : 0
  identifier               = "applicationinsights"
  resource_group_name      = var.resource_group_name
  api_management_name      = azurerm_api_management.main.name
  api_management_logger_id = azurerm_api_management_logger.app_insights[0].id

  sampling_percentage       = 100.0
  always_log_errors         = true
  log_client_ip             = true
  verbosity                 = "information"
  http_correlation_protocol = "W3C"

  frontend_request {
    body_bytes = 1024
    headers_to_log = [
      "Content-Type",
      "User-Agent",
      "Ocp-Apim-Subscription-Key"
    ]
  }

  frontend_response {
    body_bytes = 1024
    headers_to_log = [
      "Content-Type"
    ]
  }

  backend_request {
    body_bytes = 1024
    headers_to_log = [
      "Content-Type"
    ]
  }

  backend_response {
    body_bytes = 1024
    headers_to_log = [
      "Content-Type"
    ]
  }
}

# Monitor diagnostics settings
resource "azurerm_monitor_diagnostic_setting" "apim" {
  count                      = var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "${var.apim_name}-diagnostics"
  target_resource_id         = azurerm_api_management.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "GatewayLogs"
  }

  enabled_log {
    category = "WebSocketConnectionLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

# Named value example
resource "azurerm_api_management_named_value" "environment" {
  name                = "environment"
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.main.name
  display_name        = "environment"
  value               = var.tags["Environment"]
}
