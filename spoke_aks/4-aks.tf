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

  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = true
    admin_group_object_ids = [azuread_group.aks_admins.object_id]
    tenant_id              = data.azurerm_subscription.current.tenant_id
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