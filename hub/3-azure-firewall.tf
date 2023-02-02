# Generate random string for unique firewall diagnostic name
resource "random_string" "fw_diag_prefix" {
  length  = 8
  upper   = false
  special = false
  numeric  = false
}
resource "azurerm_ip_group" "ip_group_hub" {
  name                = "ipgroup-hub"
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name
  cidrs               = var.vnet_hub_address_space
}

resource "azurerm_ip_group" "ip_group_spoke" {
  name                = "ipgroup-spokeml"
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name
  cidrs               = var.vnet_ml_address_space
}

resource "azurerm_ip_group" "ip_group_spokeaks" {
  name                = "ipgroup-spokeaks"
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name
  cidrs               = var.vnet_aks_address_space
}

resource "azurerm_ip_group" "ip_group_dsvm_subnet" {
  name                = "ipgroup-jumphost"
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name
  cidrs               = var.jumphost_subnet_address_space
}

resource "azurerm_public_ip" "azure_firewall" {
  name                = "pip-azfw"
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall_policy" "base_policy" {
  name                = "afwp-base-01"
  resource_group_name = azurerm_resource_group.hub_rg.name
  location            = azurerm_resource_group.hub_rg.location
  dns {
    proxy_enabled = true
  }

}
resource "azurerm_firewall" "azure_firewall_instance" {
  name                = "afw-${var.name}"
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name
  firewall_policy_id  = azurerm_firewall_policy.base_policy.id
  sku_tier            = "Premium"
  sku_name            = "AZFW_VNet"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.azure_firewall.id
    public_ip_address_id = azurerm_public_ip.azure_firewall.id
  }

  timeouts {
    create = "60m"
    delete = "2h"
  }
  depends_on = [
    azurerm_public_ip.azure_firewall,
    azurerm_subnet.azure_firewall,
    azurerm_firewall_policy_rule_collection_group.azure_firewall_rules_collection
  ]
}

resource "azurerm_monitor_diagnostic_setting" "azure_firewall_instance" {
  name                       = "diagnostics-${var.name}-${random_string.fw_diag_prefix.result}"
  target_resource_id         = azurerm_firewall.azure_firewall_instance.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.default.id

  enabled_log {
    category = "AzureFirewallApplicationRule"
    retention_policy {
      enabled = false
    }
  }
  enabled_log {
    category = "AzureFirewallNetworkRule"
    retention_policy {
      enabled = false
    }
  }
  enabled_log {
    category = "AzureFirewallDnsProxy"
    retention_policy {
      enabled = false
    }
  }


  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }

}

resource "azurerm_firewall_policy_rule_collection_group" "azure_firewall_rules_collection" {
  name               = "afwp-base-rule-collection-group"
  firewall_policy_id = azurerm_firewall_policy.base_policy.id
  priority           = 100

  application_rule_collection {
    name     = "afwp-base-app-rule-collection"
    priority = 200
    action   = "Allow"

    rule {
      name             = "allow aks outbound"
      protocols {
        port = "80"
        type = "Http"
      }

      protocols {
        port = "443"
        type = "Https"
      }

      source_ip_groups  = [azurerm_ip_group.ip_group_spokeaks.id]
      destination_fqdns = [
        "*.cdn.mscr.io",
        "mcr.microsoft.com",
        "*.data.mcr.microsoft.com",
        "management.azure.com",
        "login.microsoftonline.com",
        "acs-mirror.azureedge.net",
        "dc.services.visualstudio.com",
        "*.opinsights.azure.com",
        "*.oms.opinsights.azure.com",
        "*.microsoftonline.com",
        "*.monitoring.azure.com",
      ]

    }

    rule {
      name = "dsvm-to-internet"
      protocols {
        type = "Https"
        port = 443
      }
      protocols {
        type = "Http"
        port = 80
      }
      source_ip_groups  = [azurerm_ip_group.ip_group_dsvm_subnet.id]
      destination_fqdns = ["*"]
    }

    rule {
      name = "aks-service-tag"
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups      = [azurerm_ip_group.ip_group_spokeaks.id]
      destination_fqdn_tags = ["AzureKubernetesService"]
    }

    rule {
      name = "files.pythonhosted.org"
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups  = [azurerm_ip_group.ip_group_spoke.id]
      destination_fqdns = ["files.pythonhosted.org", ]
    }

    rule {
      name = "ubuntu-libraries"
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups  = [azurerm_ip_group.ip_group_spoke.id]
      destination_fqdns = ["api.snapcraft.io", "motd.ubuntu.com", ]
    }

    rule {
      name = "microsoft-crls"
      protocols {
        type = "Http"
        port = 80
      }
      source_ip_groups = [azurerm_ip_group.ip_group_spoke.id]
      destination_fqdns = ["crl.microsoft.com",
        "mscrl.microsoft.com",
        "crl3.digicert.com",
      "ocsp.digicert.com"]
    }

    rule {
      name = "github-rules"
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups  = [azurerm_ip_group.ip_group_spoke.id]
      destination_fqdns = ["github.com"]
    }

    rule {
      name = "raw.githubusercontent.com"
      protocols {
        type = "Https"
        port = 443
      }
      protocols {
        type = "Http"
        port = 80
      }
      source_ip_groups  = [azurerm_ip_group.ip_group_spoke.id]
      destination_fqdns = ["raw.githubusercontent.com"]
    }

    rule {
      name = "microsoft-metrics-rules"
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups  = [azurerm_ip_group.ip_group_spoke.id]
      destination_fqdns = ["*.prod.microsoftmetrics.com"]
    }

    rule {
      name = "aks-acs-rules"
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [azurerm_ip_group.ip_group_spokeaks.id]
      destination_fqdns = ["acs-mirror.azureedge.net",
        "*.docker.io",
        "production.cloudflare.docker.com",
      "*.azurecr.io"]
    }

    rule {
      name = "microsoft-login-rules"
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups  = [
        azurerm_ip_group.ip_group_spoke.id,
        azurerm_ip_group.ip_group_spokeaks.id
      ]
      destination_fqdns = ["login.microsoftonline.com"]
    }

    rule {
      name = "graph.windows.net"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups  = [azurerm_ip_group.ip_group_spoke.id]
      destination_fqdns = ["graph.windows.net"]
    }

    rule {
      name = "anaconda.com"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups  = [azurerm_ip_group.ip_group_spoke.id]
      destination_fqdns = ["anaconda.com", "*.anaconda.com"]
    }

    rule {
      name = "anaconda.org"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups  = [azurerm_ip_group.ip_group_spoke.id]
      destination_fqdns = ["*.anaconda.org"]
    }

    rule {
      name = "pypi.org"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups  = [azurerm_ip_group.ip_group_spoke.id]
      destination_fqdns = ["pypi.org"]
    }

    rule {
      name = "cloud.r-project.org"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups  = [azurerm_ip_group.ip_group_spoke.id]
      destination_fqdns = ["cloud.r-project.org"]
    }

    rule {
      name = "pytorch.org"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups  = [azurerm_ip_group.ip_group_spoke.id]
      destination_fqdns = ["*pytorch.org"]
    }

    rule {
      name = "tensorflow.org"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups  = [azurerm_ip_group.ip_group_spoke.id]
      destination_fqdns = ["*.tensorflow.org"]
    }

    rule {
      name = "update.code.visualstudio.com"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups  = [azurerm_ip_group.ip_group_spoke.id]
      destination_fqdns = ["update.code.visualstudio.com", "*.vo.msecnd.net"]
    }

    rule {
      name = "dc.applicationinsights.azure.com"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups  = [azurerm_ip_group.ip_group_spoke.id]
      destination_fqdns = ["dc.applicationinsights.azure.com"]
    }

    rule {
      name = "dc.applicationinsights.microsoft.com"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups  = [azurerm_ip_group.ip_group_spoke.id]
      destination_fqdns = ["dc.applicationinsights.microsoft.com"]
    }

    rule {
      name = "dc.services.visualstudio.com"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups  = [azurerm_ip_group.ip_group_spoke.id]
      destination_fqdns = ["dc.services.visualstudio.com"]
    }

    rule {
      name = "azureml-instances"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups  = [azurerm_ip_group.ip_group_spoke.id]
      destination_fqdns = ["*.instances.azureml.net", "*.instances.azureml.ms"]
    }
  }

  network_rule_collection {
    name     = "afwp-base-network-rule-collection"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "hub-to-spoke-rule"
      protocols             = ["Any"]
      source_ip_groups      = [azurerm_ip_group.ip_group_spoke.id, azurerm_ip_group.ip_group_hub.id]
      destination_ip_groups = [azurerm_ip_group.ip_group_hub.id, azurerm_ip_group.ip_group_spoke.id]
      destination_ports     = ["*"]
    }

    rule {
      name                  = "aks-tcp-network-rule"
      protocols             = ["TCP"]
      source_ip_groups      = [azurerm_ip_group.ip_group_spokeaks.id]
      destination_addresses = ["*"]
      destination_ports     = ["*"] #["53","123","443","9000"]
    }

    rule {
      name                  = "aks-udp-network-rule"
      protocols             = ["UDP"]
      source_ip_groups      = [azurerm_ip_group.ip_group_spokeaks.id]
      destination_addresses = ["*"]
      destination_ports     = ["*"]#["53","123","1194"]
    }

    rule {
      name                  = "Azure-Active-Directory"
      protocols             = ["TCP"]
      source_ip_groups      = [azurerm_ip_group.ip_group_spoke.id]
      destination_addresses = ["AzureActiveDirectory"]
      destination_ports     = ["*"]
    }

    rule {
      name                  = "Azure-Machine-Learning"
      protocols             = ["TCP"]
      source_ip_groups      = [azurerm_ip_group.ip_group_spoke.id]
      destination_addresses = ["AzureMachineLearning"]
      destination_ports     = ["443"]
    }

    rule {
      name                  = "Azure-Resource-Manager"
      protocols             = ["TCP"]
      source_ip_groups      = [azurerm_ip_group.ip_group_spoke.id]
      destination_addresses = ["AzureResourceManager"]
      destination_ports     = ["443"]
    }

    rule {
      name                  = "Azure-Storage"
      protocols             = ["TCP"]
      source_ip_groups      = [azurerm_ip_group.ip_group_spoke.id]
      destination_addresses = ["Storage"]
      destination_ports     = ["443"]
    }

    rule {
      name                  = "Azure-Front-Door-Frontend"
      protocols             = ["TCP"]
      source_ip_groups      = [azurerm_ip_group.ip_group_spoke.id]
      destination_addresses = ["AzureFrontDoor.Frontend", "AzureFrontDoor.FirstParty"]
      destination_ports     = ["443"]
    }

    rule {
      name                  = "Azure-Container-Registry"
      protocols             = ["TCP"]
      source_ip_groups      = [azurerm_ip_group.ip_group_spoke.id]
      destination_addresses = ["AzureContainerRegistry"]
      destination_ports     = ["443"]
    }

    rule {
      name                  = "Azure-Key-Vault"
      protocols             = ["TCP"]
      source_ip_groups      = [azurerm_ip_group.ip_group_spoke.id]
      destination_addresses = ["AzureKeyVault"]
      destination_ports     = ["443"]
    }

    rule {
      name                  = "Microsoft-Container-Registry"
      protocols             = ["TCP"]
      source_ip_groups      = [azurerm_ip_group.ip_group_spoke.id]
      destination_addresses = ["MicrosoftContainerRegistry"]
      destination_ports     = ["443"]
    }
  }
  depends_on = [
    azurerm_ip_group.ip_group_hub,
    azurerm_ip_group.ip_group_spoke,
    azurerm_ip_group.ip_group_spokeaks
  ]
}