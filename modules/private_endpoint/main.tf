// Create Private DNS Zone for Container Registry
resource "azurerm_private_dns_zone" "pdz" {
    name                = "privatelink.azurecr.io"
    resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "pdz_vnet_link" {
    name                  = "pdz-vnet-link-"
    resource_group_name   = var.resource_group_name
    private_dns_zone_name = azurerm_private_dns_zone.pdz.name
    virtual_network_id    = var.vnet_id
    registration_enabled  = false
}


// Create Private Endpoint for Azure Container Registry
resource "azurerm_private_endpoint" "pe-appservice" {
  name                = "pe-appservice"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_ids["web"]

  private_service_connection {
    name                           = "psc-appservice"
    private_connection_resource_id = var.acr_id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }

  private_dns_zone_group {
      name                 = "app-dns-zone-group"
      private_dns_zone_ids = [azurerm_private_dns_zone.pdz.id]
  }

}