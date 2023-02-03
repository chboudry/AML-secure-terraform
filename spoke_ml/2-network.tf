# Virtual Network
resource "azurerm_virtual_network" "vnet_ml" {
  name                = "vnet-${var.name}-ml"
  address_space       = var.vnet_ml_address_space
  location            = azurerm_resource_group.rg_ml.location
  resource_group_name = azurerm_resource_group.rg_ml.name
  dns_servers         = [var.firewall_private_ip]
}

#Vnet Peering
resource "azurerm_virtual_network_peering" "direction1" {
  name                         = "${var.rg_hub_name}-to-${azurerm_resource_group.rg_ml.name}"
  resource_group_name          = var.rg_hub_name
  virtual_network_name         = var.vnet_hub_name
  remote_virtual_network_id    = azurerm_virtual_network.vnet_ml.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "direction2" {
  name                         = "${azurerm_resource_group.rg_ml.name}-to-${var.rg_hub_name}"
  resource_group_name          = azurerm_resource_group.rg_ml.name
  virtual_network_name         = azurerm_virtual_network.vnet_ml.name
  remote_virtual_network_id    = var.vnet_hub_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false
}
