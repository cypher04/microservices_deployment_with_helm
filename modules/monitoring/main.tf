# resource "azurerm_dashboard_grafana" "grafana" {
#   name                = "helmaks-grafana"
#   resource_group_name = var.resource_group_name
#   location            = var.location
#   grafana_major_version = "12"
#   api_key_enabled = true
#   deterministic_outbound_ip_enabled = true
#   public_network_access_enabled = false
#   identity {
#     type = "SystemAssigned"
#   }
  
# }

resource "azurerm_log_analytics_workspace" "log_analytics" {
  name                = "helmaks-log-analytics"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"
  
}

