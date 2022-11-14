resource "azurerm_subnet" "snet-workspace" {
  name                                           = "snet-workspace"
  resource_group_name                            = azurerm_resource_group.default.name
  virtual_network_name                           = azurerm_virtual_network.default.name
  address_prefixes                               = var.ml_subnet_address_space
  private_link_service_network_policies_enabled = false
}

# Dependent resources for Azure Machine Learning
resource "azurerm_application_insights" "default" {
  name                = "appi-${var.name}-${var.environment}"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  workspace_id        = azurerm_log_analytics_workspace.default.id
  application_type    = "web"
}

resource "azurerm_key_vault" "default" {
  name                     = "kv-${var.name}-${var.environment}"
  location                 = azurerm_resource_group.default.location
  resource_group_name      = azurerm_resource_group.default.name
  tenant_id                = data.azurerm_client_config.current.tenant_id
  sku_name                 = "premium"
  purge_protection_enabled = true

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
}

resource "azurerm_storage_account" "default" {
  name                     = "st${var.name}${var.environment}"
  location                 = azurerm_resource_group.default.location
  resource_group_name      = azurerm_resource_group.default.name
  account_tier             = "Standard"
  account_replication_type = "GRS"

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}

resource "azurerm_container_registry" "default" {
  name                = "cr${var.name}${var.environment}"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  sku                 = "Premium"
  admin_enabled       = true

  network_rule_set {
    default_action = "Deny"
  }
  public_network_access_enabled = false
}

# Machine Learning workspace
resource "azurerm_machine_learning_workspace" "default" {
  name                    = "mlw-${var.name}-${var.environment}"
  location                = azurerm_resource_group.default.location
  resource_group_name     = azurerm_resource_group.default.name
  application_insights_id = azurerm_application_insights.default.id
  key_vault_id            = azurerm_key_vault.default.id
  storage_account_id      = azurerm_storage_account.default.id
  container_registry_id   = azurerm_container_registry.default.id

  identity {
    type = "SystemAssigned"
  }
  # Disabling v1
  v1_legacy_mode_enabled  = false
  
  # Disabling public access
  public_network_access_enabled = false

  # We need an image builder as ACR can't do this in a VNET
  image_build_compute_name      = var.image_build_compute_name
  depends_on = [
    azurerm_firewall.azure_firewall_instance,
    azurerm_private_endpoint.kv_ple,
    azurerm_private_endpoint.st_ple_blob,
    azurerm_private_endpoint.storage_ple_file,
    azurerm_private_endpoint.cr_ple,
    azurerm_subnet.snet-training
  ]

}

# Private endpoints
resource "azurerm_private_endpoint" "kv_ple" {
  name                = "ple-${var.name}-${var.environment}-kv"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  subnet_id           = azurerm_subnet.snet-workspace.id

  private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.dnsvault.id]
  }

  private_service_connection {
    name                           = "psc-${var.name}-kv"
    private_connection_resource_id = azurerm_key_vault.default.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "st_ple_blob" {
  name                = "ple-${var.name}-${var.environment}-st-blob"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  subnet_id           = azurerm_subnet.snet-workspace.id

  private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.dnsstorageblob.id]
  }

  private_service_connection {
    name                           = "psc-${var.name}-st"
    private_connection_resource_id = azurerm_storage_account.default.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "storage_ple_file" {
  name                = "ple-${var.name}-${var.environment}-st-file"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  subnet_id           = azurerm_subnet.snet-workspace.id

  private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.dnsstoragefile.id]
  }

  private_service_connection {
    name                           = "psc-${var.name}-st"
    private_connection_resource_id = azurerm_storage_account.default.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "cr_ple" {
  name                = "ple-${var.name}-${var.environment}-cr"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  subnet_id           = azurerm_subnet.snet-workspace.id

  private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.dnscontainerregistry.id]
  }

  private_service_connection {
    name                           = "psc-${var.name}-cr"
    private_connection_resource_id = azurerm_container_registry.default.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "mlw_ple" {
  name                = "ple-${var.name}-${var.environment}-mlw"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  subnet_id           = azurerm_subnet.snet-workspace.id

  private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.dnsazureml.id, azurerm_private_dns_zone.dnsnotebooks.id]
  }

  private_service_connection {
    name                           = "psc-${var.name}-mlw"
    private_connection_resource_id = azurerm_machine_learning_workspace.default.id
    subresource_names              = ["amlworkspace"]
    is_manual_connection           = false
  }
}

#Network Security Groups
resource "azurerm_network_security_group" "nsg-workspace" {
  name                = "nsg-workspace"
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

resource "azurerm_subnet_network_security_group_association" "nsg-workspace-link" {
  subnet_id                 = azurerm_subnet.snet-workspace.id
  network_security_group_id = azurerm_network_security_group.nsg-workspace.id
}

resource "azurerm_route_table" "rt-workspace" {
  name                = "rt-workspace"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_route" "workspace-Internet-Route" {
  name                   = "udr-Default"
  resource_group_name    = azurerm_resource_group.default.name
  route_table_name       = azurerm_route_table.rt-workspace.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.azure_firewall_instance.ip_configuration[0].private_ip_address
}

resource "azurerm_subnet_route_table_association" "rt-workspace-link" {
  subnet_id      = azurerm_subnet.snet-workspace.id
  route_table_id = azurerm_route_table.rt-workspace.id
}
