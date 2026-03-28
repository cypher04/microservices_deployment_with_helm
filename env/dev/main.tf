resource "azurerm_resource_group" "helm" {
  name     = "helm-resource-group"
  location = "East US"
}

data "azurerm_client_config" "current" {
}

resource "helm_release" "myapp" {
    name       = "myapp"
    chart = "../../myapp"
}


module "compute" {
  source              = "../../modules/compute"

  location            = var.location
  resource_group_name      = azurerm_resource_group.helm.name
acr_name = var.acr_name
}

module "networking" {
  source              = "../../modules/networking"

  location            = var.location
  resource_group_name      = azurerm_resource_group.helm.name
  address_space       = [var.address_space]
  subnet_prefixes     = var.subnet_prefixes
  acr_name = var.acr_name
}   

module "aks" {
  source              = "../../modules/aks"

  location            = var.location
  resource_group_name      = azurerm_resource_group.helm.name
  aks_cluster_name    = var.aks_cluster_name
  node_count          = var.node_count
  node_vm_size        = var.node_vm_size
  subnet_prefixes = var.subnet_prefixes
  subnet_ids = module.networking.subnet_ids
  acr_id = module.compute.acr_id
}

resource "null_resource" "update_kubeconfig" {
  triggers = {
    cluster_id = module.aks.aks_id
  }

  provisioner "local-exec" {
    command = "az aks get-credentials --resource-group ${azurerm_resource_group.helm.name} --name ${var.aks_cluster_name} --overwrite-existing"
  }
}


module "private_endpoint" {
  source              = "../../modules/private_endpoint"

  location            = var.location
  resource_group_name      = azurerm_resource_group.helm.name
  acr_id = module.compute.acr_id
  vnet_id = module.networking.vnet_id
  subnet_ids = module.networking.subnet_ids
}
