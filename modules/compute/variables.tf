variable "resource_group_name" {
    description = "The name of the resource group to create."
    type        = string
}

variable "location" {
    description = "The Azure region where the resource group will be created."
    type        = string
}

variable "acr_name" {
    description = "The name of the Azure Container Registry to create."
    type        = string
}

