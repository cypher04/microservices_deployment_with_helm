output "subnet_ids" {
    value = {
        web     = azurerm_subnet.web.id
        app     = azurerm_subnet.app.id
        aks     = azurerm_subnet.aks_subnet.id
        database = azurerm_subnet.database.id
    }
}

output "vnet_id" {
    value = azurerm_virtual_network.vnet.id
}

output "database_subnet" {
    value = azurerm_subnet.database.id
}