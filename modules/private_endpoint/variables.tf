variable "resource_group_name" {
  description = "The name of the resource group in which the private endpoint will be created."
  type        = string

}

variable "location" {
  description = "The Azure region where the private endpoint will be created."
  type        = string
}


variable "vnet_id" {
    description = "The ID of the virtual network to which the private endpoint will be linked."
    type        = string
}

variable "subnet_ids" {
    description = "A map of subnet IDs to be used for the private endpoint."
    type        = map(string)
}

variable "acr_id" {
    description = "The ID of the Azure Container Registry to which the private endpoint will be connected."
    type        = string
}

variable "database_subnet" {
    description = "The ID of the subnet to be used for the PostgreSQL server private endpoint."
    type        = string
}

