# Spoke AKS
resource "azurerm_resource_group" "aks" {
  name     = local.rg_name
  location = var.location
}







