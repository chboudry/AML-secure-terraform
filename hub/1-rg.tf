#Hub Resource Group
resource "azurerm_resource_group" "hub_rg" {
  name     = "rg-${var.name}-hub"
  location = var.location
}