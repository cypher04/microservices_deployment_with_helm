resource "azurerm_resource_group" "helm" {
  name     = "helm-resource-group"
  location = "East US"
}

data "azurerm_client_config" "current" {
}





