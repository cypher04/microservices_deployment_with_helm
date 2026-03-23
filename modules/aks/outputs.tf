
output "client_certificate" {
    description = "The client certificate for the AKS cluster."
    value       = azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_certificate
    sensitive = true
}

output "kube_config" {
    description = "The kube config for the AKS cluster."
    value       = azurerm_kubernetes_cluster.aks.kube_config_raw
    sensitive = true
}