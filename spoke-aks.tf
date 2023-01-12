# Virtual Network
resource "azurerm_virtual_network" "aks" {
  name                = "vnet-${var.name}-aks"
  address_space       = var.vnet_aks_address_space
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_servers         = [azurerm_firewall.azure_firewall_instance.ip_configuration[0].private_ip_address]
  depends_on = [
    azurerm_virtual_network.hub,
    azurerm_firewall.azure_firewall_instance
  ]
}

resource "azurerm_subnet" "snet-aks" {
  name                                           = "snet-aks"
  resource_group_name                            = azurerm_resource_group.aks.name
  virtual_network_name                           = azurerm_virtual_network.aks.name
  address_prefixes                               = var.aks_subnet_address_space
}

resource "azurerm_virtual_network_peering" "aksdirection1" {
  name                         = "${azurerm_resource_group.aks.name}-to-${azurerm_resource_group.default.name}"
  resource_group_name          = azurerm_resource_group.hub_rg.name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.aks.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false
  depends_on = [
    azurerm_virtual_network.hub,
    azurerm_virtual_network.aks
  ]

}

resource "azurerm_virtual_network_peering" "aksdirection2" {
  name                         = "${azurerm_resource_group.aks.name}-to-${azurerm_resource_group.hub_rg.name}"
  resource_group_name          = azurerm_resource_group.aks.name
  virtual_network_name         = azurerm_virtual_network.aks.name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false
  depends_on = [
    azurerm_virtual_network.hub,
    azurerm_virtual_network.aks
  ]

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
  next_hop_in_ip_address = azurerm_firewall.azure_firewall_instance.ip_configuration[0].private_ip_address
}

resource "azurerm_subnet_route_table_association" "rt-aks-link" {
  subnet_id      = azurerm_subnet.snet-aks.id
  route_table_id = azurerm_route_table.rt-aks.id
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${var.name}"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = "${var.name}-k8s"

  default_node_pool {
    name           = "system"
    node_count     = 3
    vm_size        = "Standard_DS2_v2"
    vnet_subnet_id = azurerm_subnet.snet-aks.id
    os_disk_size_gb = "80"
    os_disk_type = "Ephemeral"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = "userDefinedRouting"
  }

  identity {
    type = "SystemAssigned"
  }
  
  oms_agent {
      log_analytics_workspace_id = azurerm_log_analytics_workspace.default.id
  }

  depends_on = [
    azurerm_firewall.azure_firewall_instance,
    azurerm_firewall_policy_rule_collection_group.azure_firewall_rules_collection,
    azurerm_subnet.snet-aks
  ]
}

data "azurerm_monitor_diagnostic_categories" "aksdiag" {
  resource_id = azurerm_kubernetes_cluster.aks.id
}

resource "azurerm_monitor_diagnostic_setting" "aks_diag" {
  name                       = "diagnostics-aks45617"
  target_resource_id         = azurerm_kubernetes_cluster.aks.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.default.id

  dynamic "log" {
    for_each = data.azurerm_monitor_diagnostic_categories.aksdiag.logs
    content {
      category = log.value
      enabled  = true
      retention_policy {
        enabled = false
      }
    }
  }

  metric {
    category = "AllMetrics"

  retention_policy {
      enabled = false
    }
  }
}

# How to install the ml extension on aks cluster
# Documentation :
# https://learn.microsoft.com/en-us/azure/templates/microsoft.kubernetesconfiguration/2022-03-01/extensions?pivots=deployment-language-terraform

# ARM example :
# https://github.com/Azure/AML-Kubernetes/blob/master/files/deployextension.json

# My trick, install the ml extension through az cli command, then :
# az k8s-extension list --cluster-name CLUSTER_NAME --resource-group RG_NAME --cluster-type managedClusters
# will give you a readable configurationSettings to copy from

resource "azapi_resource" "mlextension" {
  type = "Microsoft.KubernetesConfiguration/extensions@2022-11-01"
  name = "aksextml"
  parent_id = azurerm_kubernetes_cluster.aks.id
  identity {
    type = "SystemAssigned"
  }
  body = jsonencode({
    properties = {
      autoUpgradeMinorVersion = true
      configurationProtectedSettings = {}
      configurationSettings = {
            allowInsecureConnections="true"
            clusterId= azurerm_kubernetes_cluster.aks.id
            clusterPurpose= "DevTest"
            cluster_name= azurerm_kubernetes_cluster.aks.name
            cluster_name_friendly= azurerm_kubernetes_cluster.aks.name
            enableTraining="true"
            enableInference= "true"
            inferenceRouterHA= "true"
            inferenceRouterServiceType= "ClusterIP"
            jobSchedulerLocation= azurerm_kubernetes_cluster.aks.location
            location=azurerm_kubernetes_cluster.aks.location
            domain= azurerm_kubernetes_cluster.aks.location
            "prometheus.prometheusSpec.externalLabels.cluster.name"= azurerm_kubernetes_cluster.aks.id
            "nginxIngress.enabled"= "true"
            "relayserver.enabled"= "false"
            "servicebus.enabled"= "false"
            installNvidiaDevicePlugin= "false"
            installPromOp="true"
            installVolcano="true"
            installDcgmExporter="false"    
      }
      extensionType = "microsoft.azureml.kubernetes"
      releaseTrain = "stable"
      scope = {
        cluster = {
          releaseNamespace = "azureml"
        }
      }
    }
  })
  depends_on = [
    azurerm_kubernetes_cluster.aks
  ]
}