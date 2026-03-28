
output "client_certificate" {
    description = "The client certificate for the AKS cluster."
    value       = azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate
    sensitive = true
}

output "client_key" {
    description = "The client key for the AKS cluster."
    value       = azurerm_kubernetes_cluster.aks.kube_config[0].client_key
    sensitive = true
}

output "cluster_ca_certificate" {
    description = "The cluster CA certificate for the AKS cluster."
    value       = azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate
    sensitive = true
}

output "host" {
    description = "The host for the AKS cluster."
    value       = azurerm_kubernetes_cluster.aks.kube_config[0].host
}

output "kube_config" {
    description = "The kube config for the AKS cluster."
    value       = azurerm_kubernetes_cluster.aks.kube_config_raw
    sensitive = true
}



output "aks_id" {
    description = "The ID of the AKS cluster."
    value       = azurerm_kubernetes_cluster.aks.id
}

output "aks_resource" {
    description = "The AKS cluster resource."
    value       = azurerm_kubernetes_cluster.aks
}