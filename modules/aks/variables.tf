variable "aks_cluster_name" {
    description = "The name of the AKS cluster."
    type        = string
}

variable "resource_group_name" {
    description = "The name of the resource group."
    type        = string
}

variable "location" {
    description = "The Azure region where the AKS cluster will be created."
    type        = string
}

variable "node_count" {
    description = "The number of nodes in the AKS cluster."
    type        = number
    default     = 3
}

variable "node_vm_size" {
    description = "The size of the virtual machines for the AKS cluster nodes."
    type        = string
    default     = "Standard_DS2_v2"
}

variable "subnet_prefixes" {
    description = "The subnet prefixes for the AKS cluster."
    type        = map(string)
}

variable "subnet_ids" {
    description = "The subnet IDs for the AKS cluster."
    type        = map(string)
}

variable "acr_id" {
    description = "The ID of the Azure Container Registry."
    type        = string
}