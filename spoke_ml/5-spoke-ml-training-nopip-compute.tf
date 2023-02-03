# Generate random string for unique compute instance name
resource "random_string" "ci_prefix" {
  length  = 8
  upper   = false
  special = false
  numeric  = false
}

# NO PIP Compute cluster
# https://learn.microsoft.com/en-us/azure/templates/microsoft.machinelearningservices/2022-06-01-preview/workspaces/computes?pivots=deployment-language-terraform#compute-objects-2
# https://learn.microsoft.com/en-us/azure/templates/microsoft.machinelearningservices/2022-06-01-preview/workspaces/computes?pivots=deployment-language-terraform#amlcomputeproperties-2
# 
resource "azapi_resource" "nopip_compute_cluster" {
  name = var.image_build_compute_name
  parent_id = azurerm_machine_learning_workspace.default.id
  type = "Microsoft.MachineLearningServices/workspaces/computes@2022-06-01-preview"

  location = "westeurope"
  body = jsonencode({
    properties = {
      computeType      = "AmlCompute"
      disableLocalAuth = true
      properties = {
        enableNodePublicIp = false
        vmSize = "STANDARD_DS2_V2"
        vmPriority = "LowPriority"
        subnet = {
          id = "${azurerm_subnet.snet-training.id}"
        }
        scaleSettings={
          minNodeCount                       = 0
          maxNodeCount                      = 1
          nodeIdleTimeBeforeScaleDown = "PT15M" # 15 minutes
        }
      }
    }
  })
  depends_on = [
    azurerm_subnet.snet-training,
    azurerm_private_endpoint.mlw_ple,
    azurerm_subnet_network_security_group_association.nsg-training-link
  ]
}

# NO PIP Compute instance
# https://learn.microsoft.com/en-us/azure/templates/microsoft.machinelearningservices/workspaces/computes?pivots=deployment-language-terraform
# 
resource "azapi_resource" "nopip_compute_instance" {
  name = "${random_string.ci_prefix.result}-instance"
  parent_id = azurerm_machine_learning_workspace.default.id
  type = "Microsoft.MachineLearningServices/workspaces/computes@2022-06-01-preview"

  location = "westeurope"
  body = jsonencode({
    properties = {
      computeType      = "ComputeInstance"
      disableLocalAuth = true
      properties = {
        enableNodePublicIp = false
        vmSize = "STANDARD_DS2_V2"
        subnet = {
          id = "${azurerm_subnet.snet-training.id}"
        }
      }
    }
  })
  depends_on = [
    azurerm_subnet.snet-training,
    azurerm_private_endpoint.mlw_ple,
    azurerm_subnet_network_security_group_association.nsg-training-link,
  ]
}


# PIP Compute instance
# resource "azurerm_machine_learning_compute_instance" "compute_instance" {
#   name                          = "${random_string.ci_prefix.result}instance"
#   location                      = azurerm_resource_group.default.location
#   machine_learning_workspace_id = azurerm_machine_learning_workspace.default.id
#   virtual_machine_size          = "STANDARD_DS2_V2"
#   subnet_resource_id            = azurerm_subnet.snet-training.id

#   depends_on = [
#     azurerm_private_endpoint.mlw_ple
#   ]
# }

# PIP Compute cluster
# resource "azurerm_machine_learning_compute_cluster" "compute" {
#   name                          = "cpu-cluster"
#   location                      = azurerm_resource_group.default.location
#   machine_learning_workspace_id = azurerm_machine_learning_workspace.default.id
#   vm_priority                   = "Dedicated"
#   vm_size                       = "STANDARD_DS2_V2"
#   subnet_resource_id            = azurerm_subnet.snet-training.id

#   identity {
#     type = "SystemAssigned"
#   }

#   scale_settings {
#     min_node_count                       = 0
#     max_node_count                       = 3
#     scale_down_nodes_after_idle_duration = "PT15M" # 15 minutes
#   }
#   depends_on = [
#     azurerm_private_endpoint.mlw_ple
#   ]
# }