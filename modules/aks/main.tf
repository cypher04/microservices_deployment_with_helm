resource "azurerm_kubernetes_cluster" "aks" {
    name                = var.aks_cluster_name
    location            = var.location
    resource_group_name = var.resource_group_name
    dns_prefix          = "${var.aks_cluster_name}-dns"
    
    default_node_pool {
        name       = "default"
        node_count = var.node_count
        vm_size    = var.node_vm_size
        vnet_subnet_id = var.subnet_ids["aks"]
    }
    
    identity {
        type = "SystemAssigned"
    }
}


resource "azurerm_role_assignment" "aks-acr" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  
}

