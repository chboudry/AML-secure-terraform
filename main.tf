terraform {
  required_version = ">=1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.29.1"
    }
    azapi = {
      source  = "Azure/azapi"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azapi" {
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "default" {
  name     = "rg-${var.name}-${var.environment}"
  location = var.location
}

#Hub Resource Group
resource "azurerm_resource_group" "hub_rg" {
  name     = "rg-hub-${var.name}-${var.environment}"
  location = var.location
}