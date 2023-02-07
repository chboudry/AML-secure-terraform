resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_name
  location            = var.location
  resource_group_name = var.rg_name
  dns_prefix          = "${var.deployment_name}-k8s"

  default_node_pool {
    name           = "system"
    node_count     = 3
    vm_size        = "Standard_DS2_v2"
    vnet_subnet_id = var.subnet_id
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
      log_analytics_workspace_id = var.law_id
  }
}

resource "azurerm_role_assignment" "akstomanagevnet" {
 scope = variable.vnet_id
 role_definition_id = "/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7" #Network Contributor
 principal_id = azurerm_kubernetes_cluster.aks.identity
}

data "azurerm_monitor_diagnostic_categories" "aksdiag" {
  resource_id = azurerm_kubernetes_cluster.aks.id
}

resource "azurerm_monitor_diagnostic_setting" "aks_diag" {
  name                       = "diagnostics-aks45617"
  target_resource_id         = azurerm_kubernetes_cluster.aks.id
  log_analytics_workspace_id = var.law_id

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.aksdiag.log_category_types
    content {
      category = enabled_log.value
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