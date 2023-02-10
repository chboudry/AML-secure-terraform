resource "azurerm_virtual_network" "aks" {
  name                = local.vnet_name
  address_space       = var.vnet_aks_address_space
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_servers         = [var.firewall_private_ip]
}

resource "azurerm_subnet" "snet-aks" {
  name                                           = "snet-aks"
  resource_group_name                            = azurerm_resource_group.aks.name
  virtual_network_name                           = azurerm_virtual_network.aks.name
  address_prefixes                               = var.aks_subnet_address_space
}

resource "azurerm_virtual_network_peering" "aksdirection1" {
  name                         = "hub-to-aks"
  resource_group_name          = var.rg_hub_name
  virtual_network_name         = var.vnet_hub_name
  remote_virtual_network_id    = azurerm_virtual_network.aks.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "aksdirection2" {
  name                         = "aks-to-hub"
  resource_group_name          = azurerm_resource_group.aks.name
  virtual_network_name         = azurerm_virtual_network.aks.name
  remote_virtual_network_id    = var.vnet_hub_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_route_table" "rt-aks" {
  name                          = "rt-aks"
  location                      = azurerm_resource_group.aks.location
  resource_group_name           = azurerm_resource_group.aks.name
}

resource "azurerm_route" "aks-Internet-Route" {
  name                   = "udr-Default"
  resource_group_name    = azurerm_resource_group.aks.name
  route_table_name       = azurerm_route_table.rt-aks.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.firewall_private_ip
}

resource "azurerm_subnet_route_table_association" "rt-aks-link" {
  subnet_id      = azurerm_subnet.snet-aks.id
  route_table_id = azurerm_route_table.rt-aks.id
}