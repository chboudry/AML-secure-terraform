# Spoke AKS
resource "azurerm_resource_group" "aks" {
  name     = "rg-${var.name}-aks"
  location = var.location
}







