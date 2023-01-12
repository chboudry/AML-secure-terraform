# Virtual Network
resource "azurerm_virtual_network" "default" {
  name                = "vnet-${var.name}-ml"
  address_space       = var.vnet_ml_address_space
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  dns_servers         = [azurerm_firewall.azure_firewall_instance.ip_configuration[0].private_ip_address]
  depends_on = [
    azurerm_virtual_network.hub,
    azurerm_firewall.azure_firewall_instance
  ]
}

