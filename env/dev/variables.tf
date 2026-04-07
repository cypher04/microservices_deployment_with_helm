variable "resource_group_name" {
    description = "The name of the resource group to create."
    type        = string
}

variable "location" {
    description = "The Azure region where the resource group will be created."
    type        = string
}

variable "aks_cluster_name" {
    description = "The name of the AKS cluster to create."
    type        = string
}

variable "acr_name" {
    description = "The name of the Azure Container Registry to create."
    type        = string
}

variable "node_count" {
    description = "The number of nodes to create in the AKS cluster."
    type        = number
}


variable "node_vm_size" {
    description = "The size of the virtual machines to use for the AKS cluster nodes."
    type        = string
}

variable "address_space" {
    description = "The address space for the virtual network."
    type        = string
}

variable "subnet_prefixes" {
    description = "A map of subnet names to their respective CIDR prefixes."
    type        = map(string)
}

variable "db_user" {
    description = "The username for the database."
    type        = string
}

variable "db_password" {
    description = "The password for the database."
    type        = string
    sensitive   = true
}

variable "db_host" {
    description = "The hostname of the database server."
    type        = string
}

variable "db_name" {
    description = "The name of the database."
    type        = string
}

variable "postgresql_admin_username" {
    description = "The administrator username for the PostgreSQL server."
    type        = string
}

variable "postgresql_admin_password" {
    description = "The administrator password for the PostgreSQL server."
    type        = string
    sensitive   = true
}
