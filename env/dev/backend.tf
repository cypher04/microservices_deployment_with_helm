// backend configuration for Terraform state
terraform {
  backend "azurerm" {
    resource_group_name  = "helmaksdev-rg"
    storage_account_name = "helmaksstatedev"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}