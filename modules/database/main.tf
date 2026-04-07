resource "azurerm_postgresql_flexible_server" "postgresql" {
  name                = "helmaks-postgresql"
  resource_group_name = var.resource_group_name
  location            = var.location
  version             = "12"
  administrator_login          = var.postgresql_admin_username
  administrator_password = var.postgresql_admin_password
  storage_mb                   = 32768
  storage_tier = "P4"
  sku_name                     = "B_Standard_B1ms"
  delegated_subnet_id           = var.subnet_ids["database"]
  zone = "2"
  private_dns_zone_id = var.private_dns_zone_vl_id
  public_network_access_enabled = false


depends_on = [ var.private_dns_zone_vl_id ]
  
}

resource "azurerm_postgresql_flexible_server_database" "postgreql_server" {
  name                = "myappdb"
  server_id         = azurerm_postgresql_flexible_server.postgresql.id
  charset             = "UTF8"
  collation           = "en_US.utf8"
}
