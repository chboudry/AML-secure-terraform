# It is required to redefine module providers explicity as azure/api does not come from hashicorp.

terraform {
  required_version = ">=1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.29.1"
    }
    azapi = {
      source  = "azure/azapi"
    }
  }
}