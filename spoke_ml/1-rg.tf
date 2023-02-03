#Spoke ML
resource "azurerm_resource_group" "rg_ml" {
  name     = "rg-${var.name}-ml"
  location = var.location
}