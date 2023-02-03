# It is required to redefine module providers explicity as azure/api does not come from hashicorp.

terraform {
  required_version = ">=1.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.17.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.41.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.1.0"
    }
  }
}

provider "azurerm" {
  features {}
}