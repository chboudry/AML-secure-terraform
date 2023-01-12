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

#Hub Resource Group
resource "azurerm_resource_group" "hub_rg" {
  name     = "rg-${var.name}-hub"
  location = var.location
}

#Spoke ML
resource "azurerm_resource_group" "default" {
  name     = "rg-${var.name}-ml"
  location = var.location
}

#Spoke AKS
resource "azurerm_resource_group" "aks" {
  name     = "rg-${var.name}-aks"
  location = var.location
}

