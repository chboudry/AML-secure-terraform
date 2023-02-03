# It is required to redefine module providers explicity as azure/api does not come from hashicorp.

terraform {
  required_version = ">=1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.41.0"
    }
    azapi = {
      source  = "azure/azapi"
    }
  }
}

provider "azurerm" {
  features {}
}