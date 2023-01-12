resource "azurerm_subnet" "snet-training" {
  name                                           = "snet-training"
  resource_group_name                            = azurerm_resource_group.default.name
  virtual_network_name                           = azurerm_virtual_network.default.name
  address_prefixes                               = var.training_subnet_address_space
  private_link_service_network_policies_enabled = false
  private_endpoint_network_policies_enabled = false
}

#Network Security Groups for NO public IP
resource "azurerm_network_security_group" "nsg-training" {
  name                = "nsg-training"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name

  security_rule {
    name                       = "InboundBatchNodeManagement"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "29876-29877"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "InboundAzureMachineLearning"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "44224"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "AzureActiveDirectory"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80","443"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureActiveDirectory"
  }

  security_rule {
    name                       = "AzureMachineLearning"
    priority                   = 130
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["443","8787","18881"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureMachineLearning"
  }

  security_rule {
    name                       = "BatchNodeManagement.${var.location}"
    priority                   = 140
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "BatchNodeManagement.${var.location}"
  }

  security_rule {
    name                       = "AzureResourceManager"
    priority                   = 150
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureResourceManager"
  }

  security_rule {
    name                       = "Storage.${var.location}"
    priority                   = 160
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["443","445"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Storage.${var.location}"
  }

  security_rule {
    name                       = "AzureFrontDoor.FrontEnd"
    priority                   = 170
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureFrontDoor.FrontEnd"
  }

  security_rule {
    name                       = "MicrosoftContainerRegistry.${var.location}"
    priority                   = 180
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "MicrosoftContainerRegistry.${var.location}"
  }

  security_rule {
    name                       = "AzureFrontDoor.FirstParty"
    priority                   = 190
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureFrontDoor.FirstParty"
  }

  security_rule {
    name                       = "AzureMonitor"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureMonitor"
  }
  
  security_rule {
    name                       = "Keyvault.${var.location}"
    priority                   = 210
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureKeyVault.${var.location}"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg-training-link" {
  subnet_id                 = azurerm_subnet.snet-training.id
  network_security_group_id = azurerm_network_security_group.nsg-training.id
}

# UDR for compute instance and compute clusters
resource "azurerm_route_table" "rt-training" {
  name                = "rt-training"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_route" "training-Internet-Route" {
  name                   = "udr-Default"
  resource_group_name    = azurerm_resource_group.default.name
  route_table_name       = azurerm_route_table.rt-training.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.azure_firewall_instance.ip_configuration[0].private_ip_address
}

resource "azurerm_subnet_route_table_association" "rt-training-link" {
  subnet_id      = azurerm_subnet.snet-training.id
  route_table_id = azurerm_route_table.rt-training.id
}
