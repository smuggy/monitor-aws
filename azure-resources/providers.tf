// We strongly recommend using the required_providers block to set the
// Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }
  }
}

// Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}

  subscription_id = "8e7b34c5-7818-4b4c-858d-b77a49ebb638"
  tenant_id       = "011d7b1d-8a2b-4694-b667-78ea7d67f96a"
}
