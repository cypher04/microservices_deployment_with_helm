resource "azurerm_virtual_network" "vnet" {
    name                = "helmaks-vnet"
    address_space       = var.address_space
    location            = var.location
    resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "web" {
    name                 = "web-subnet"
    resource_group_name  = var.resource_group_name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = [var.subnet_prefixes["web"]]

}

resource "azurerm_subnet" "app" {
    name                 = "app-subnet"
    resource_group_name  = var.resource_group_name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = [var.subnet_prefixes["app"]]
}


resource "azurerm_subnet" "aks_subnet" {
    name                 = "aks-subnet"
    resource_group_name  = var.resource_group_name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = [var.subnet_prefixes["aks"]]
}

resource "azurerm_subnet" "database" {
    name                 = "database-subnet"
    resource_group_name  = var.resource_group_name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = [var.subnet_prefixes["database"]]
}

