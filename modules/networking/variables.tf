variable "resource_group_name" {
    description = "The name of the resource group in which to create the container registry."
    type        = string
}

variable "location" {
    description = "The Azure region where the container registry will be created."
    type        = string
}

variable "acr_name" {
    description = "The name of the Azure Container Registry to create."
    type        = string
}

variable "address_space" {
    description = "The address space for the virtual network."
    type        = list(string)
}

variable "subnet_prefixes" {
    description = "A map of subnet names to their address prefixes."
    type        = map(string)
}


