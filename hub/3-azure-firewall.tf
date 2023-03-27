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

  network_rule_collection {
    name     = "HUB-network"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "hub-to-spoke-rule"
      protocols             = ["Any"]
      source_ip_groups      = [azurerm_ip_group.ip_group_spoke.id, azurerm_ip_group.ip_group_hub.id]
      destination_ip_groups = [azurerm_ip_group.ip_group_hub.id, azurerm_ip_group.ip_group_spoke.id, azurerm_ip_group.ip_group_spokeaks.id]
      destination_ports     = ["*"]
    }
  }

  application_rule_collection {
    name     = "HUB-application"
    priority = 101
    action   = "Allow"
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
  }

  network_rule_collection {
    name     = "AML-minimal-network-configuration"
    priority = 200
    action   = "Allow"

    # Authentication using Azure AD.
    rule {
      name                  = "AzureActiveDirectory" 
      protocols             = ["TCP"]
      source_ip_groups      = [azurerm_ip_group.ip_group_spoke.id]
      destination_addresses = ["AzureActiveDirectory"]
      destination_ports     = ["443"] #80
    }

    # Using Azure Machine Learning services. Python intellisense in notebooks uses port 18881.
    rule {
      name                  = "AzureMachineLearning-TCP" 
      protocols             = ["TCP"]
      source_ip_groups      = [azurerm_ip_group.ip_group_spoke.id]
      destination_addresses = ["AzureMachineLearning"]
      destination_ports     = ["443", "18881"]
    }

    # Using Azure Machine Learning services. Creating, updating, and deleting an Azure Machine Learning compute instance uses port 5831.
    rule {
      name                  = "Azure-Machine-Learning-UDP"
      protocols             = ["UDP"]
      source_ip_groups      = [azurerm_ip_group.ip_group_spoke.id]
      destination_addresses = ["AzureMachineLearning"]
      destination_ports     = ["5831"]
    }

    # Communication Azure Batch.
    rule {
      name                  = "BatchNodeManagement"
      protocols             = ["TCP"]
      source_ip_groups      = [azurerm_ip_group.ip_group_spoke.id]
      destination_addresses = ["BatchNodeManagement"]#.region
      destination_ports     = ["443"]
    }
    
    # Creation of Azure resources with Azure Machine Learning.
    rule {
      name                  = "Azure-Resource-Manager"
      protocols             = ["TCP"]
      source_ip_groups      = [azurerm_ip_group.ip_group_spoke.id]
      destination_addresses = ["AzureResourceManager"]
      destination_ports     = ["443"]
    }

    # Access data stored in the Azure Storage Account for compute cluster and compute instance. This outbound can be used to exfiltrate data. For more information, see Data exfiltration protection.
    rule {
      name                  = "Storage"
      protocols             = ["TCP"]
      source_ip_groups      = [azurerm_ip_group.ip_group_spoke.id]
      destination_addresses = ["Storage"]#.region + service policy
      destination_ports     = ["443"]
    }

    # Global entry point for Azure Machine Learning studio. Store images and environments for AutoML.
    rule {
      name                  = "AzureFrontDoor.Frontend"
      protocols             = ["TCP"]
      source_ip_groups      = [azurerm_ip_group.ip_group_spoke.id]
      destination_addresses = ["AzureFrontDoor.Frontend"]
      destination_ports     = ["443"]
    }

    # Access docker images provided by Microsoft.
    rule {
      name                  = "MicrosoftContainerRegistry"
      protocols             = ["TCP"]
      source_ip_groups      = [azurerm_ip_group.ip_group_spoke.id]
      destination_addresses = ["MicrosoftContainerRegistry"]#.region
      destination_ports     = ["443"]
    }

    # Access docker images provided by Microsoft.
    rule {
      name                  = "AzureFrontDoor.FirstParty"
      protocols             = ["TCP"]
      source_ip_groups      = [azurerm_ip_group.ip_group_spoke.id]
      destination_addresses = ["AzureFrontDoor.FirstParty"]
      destination_ports     = ["443"]
    }

    # Used to log monitoring and metrics to Azure Monitor. Only needed if you haven't secured Azure Monitor for the workspace. This outbound is also used to log information for support incidents.
    rule {
      name                  = "AzureMonitor"
      protocols             = ["TCP"]
      source_ip_groups      = [azurerm_ip_group.ip_group_spoke.id]
      destination_addresses = ["AzureMonitor"]
      destination_ports     = ["443"]
    }
  }

  application_rule_collection {
    name     = "AML-training-deploying-recommended-configuration"
    priority = 202
    action   = "Allow"
  
    rule {
      name = "anaconda.com"
      description = "Used to install default packages."
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
      description = "Used to get repo data"
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
      description = "Used to list dependencies from the default index, if any, and the index isn't overwritten by user settings. If the index is overwritten, you must also allow *.pythonhosted.org."
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
      name = "pytorch.org"
      description = "Used by some examples based on PyTorch."
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
      description = "Used by some examples based on Tensorflow."
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

    # Used to retrieve Visual Studio Code server bits that are installed on the compute instance through a setup script.
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
  }

  network_rule_collection {
    name     = "AML-RStudio-Use"
    priority = 250
    action   = "Allow"

    # Used when connecting to RStudio on a compute instance
    rule {
      name                  = "AML-RStudio"
      protocols             = ["TCP"]
      source_ip_groups      = [azurerm_ip_group.ip_group_spoke.id]
      destination_addresses = ["AzureMachineLearning"]
      destination_ports     = ["8787"]
    }
  }

  application_rule_collection {
    name     = "AML-RStudio"
    priority = 251
    action   = "Allow"

    # Used when installing CRAN packages for R development.
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
      name = "AllowRStudioInstall"
      description = "AllowRStudioInstall"
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups  = [azurerm_ip_group.ip_group_spoke.id]
      destination_fqdns = ["ghcr.io", "pkg-containers.githubusercontent.com"]
    }
  }

  application_rule_collection {
    name     = "AML-Customization"
    priority = 260
    action   = "Allow"

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
  }

  network_rule_collection {
    name     = "AKS-network"
    priority = 300
    action   = "Allow"

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
  }

  application_rule_collection {
    name     = "AKS-application-configuration"
    priority = 301
    action   = "Allow"

    rule {
      name = "allow aks outbound"
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
      name = "aks-service-tag"
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups      = [azurerm_ip_group.ip_group_spokeaks.id]
      destination_fqdn_tags = ["AzureKubernetesService"]
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
  }

  depends_on = [
    azurerm_ip_group.ip_group_hub,
    azurerm_ip_group.ip_group_spoke,
    azurerm_ip_group.ip_group_spokeaks
  ]
}