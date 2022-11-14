resource "azurerm_subnet" "snet-inference" {
  name                                           = "snet-inference"
  resource_group_name                            = azurerm_resource_group.default.name
  virtual_network_name                           = azurerm_virtual_network.default.name
  address_prefixes                               = var.inference_subnet_address_space
  private_link_service_network_policies_enabled = false
}

resource "azurerm_network_security_group" "nsg-inference" {
  name                = "nsg-inference"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_subnet_network_security_group_association" "nsg-ainferenceks-link" {
  subnet_id                 = azurerm_subnet.snet-inference.id
  network_security_group_id = azurerm_network_security_group.nsg-inference.id
}

# Inferencing Route
resource "azurerm_route_table" "rt-inference" {
  name                = "rt-inference"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_route" "inference-default-Route" {
  name                   = "udr-Default"
  resource_group_name    = azurerm_resource_group.default.name
  route_table_name       = azurerm_route_table.rt-inference.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.azure_firewall_instance.ip_configuration[0].private_ip_address
}

resource "azurerm_subnet_route_table_association" "rt-inference-link" {
  subnet_id      = azurerm_subnet.snet-inference.id
  route_table_id = azurerm_route_table.rt-inference.id
}