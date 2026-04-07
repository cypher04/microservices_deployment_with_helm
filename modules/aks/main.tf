resource "azurerm_kubernetes_cluster" "aks" {
    name                = var.aks_cluster_name
    location            = var.location
    resource_group_name = var.resource_group_name
    dns_prefix          = "${var.aks_cluster_name}-dns"
    sku_tier           = "Standard"
    
    
    default_node_pool {
        name       = "default"
        node_count = var.node_count
        vm_size    = var.node_vm_size
        vnet_subnet_id = var.subnet_ids["aks"]
    }
    
    identity {
        type = "SystemAssigned"
    }


    network_profile {
        network_plugin    = "azure"
        
        service_cidr      = "10.2.0.0/16"
        dns_service_ip    = "10.2.0.10"
}

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_id
  }
}

resource "azurerm_role_assignment" "aks-acr" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  
}

resource "kubernetes_namespace_v1" "myapp" {
  metadata {
    name = "myapp"
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
}

resource "kubernetes_secret_v1" "example" {
  metadata {
    name      = "basic-auth"
    namespace = kubernetes_namespace_v1.myapp.metadata[0].name
  }

  depends_on = [kubernetes_namespace_v1.myapp]

  data = {
    username = var.db_user
    password = var.db_password
    host     = var.db_host
    name     = var.db_name
    db_port  = "5432"
  }

  type = "Opaque"
}
