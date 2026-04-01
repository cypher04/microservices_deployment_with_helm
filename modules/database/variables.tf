variable "resource_group_name" {
  description = "The name of the resource group in which to create the PostgreSQL server."
  type        = string
}

variable "location" {
  description = "The location in which to create the PostgreSQL server."
  type        = string
}

variable "postgresql_admin_username" {
  description = "The administrator username for the PostgreSQL server."
  type        = string
}

variable "postgresql_admin_password" {
  description = "The administrator password for the PostgreSQL server."
  type        = string
}

variable "subnet_ids" {
  description = "A map of subnet IDs for the PostgreSQL server."
  type        = map(string)
}

variable "private_dns_zone_vl_id" {
    description = "The ID of the private DNS zone linked to the PostgreSQL server."
    type        = string
}
