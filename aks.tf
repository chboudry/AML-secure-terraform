# This only install an AKS without the ML extension
# We don't have any terrform code for the extension yet
# To install the extension, follow below :
# Locally : 
# az aks get-credentials --resource-group <your-RG-name> --name <your-AKS-cluster-name>
# az extension add --name k8s-extension
# az k8s-extension create --name <extension-name> --extension-type Microsoft.AzureML.Kubernetes --config enableTraining=True enableInference=True inferenceRouterServiceType=LoadBalancer allowInsecureConnections=True inferenceLoadBalancerHA=False --cluster-type managedClusters --cluster-name <your-AKS-cluster-name> --resource-group <your-RG-name> --scope cluster

# resource "azurerm_kubernetes_cluster" "aks" {
#   name                = "aks-${var.name}-${var.environment}"
#   location            = azurerm_resource_group.default.location
#   resource_group_name = azurerm_resource_group.default.name
#   dns_prefix          = "${var.name}-k8s"

#   default_node_pool {
#     name           = "system"
#     node_count     = 1
#     vm_size        = "Standard_DS2_v2"
#     vnet_subnet_id = azurerm_subnet.snet-aks.id
#   }

#   network_profile {
#     network_plugin    = "azure"
#     load_balancer_sku = "standard"
#     outbound_type     = "userDefinedRouting"
#   }

#   identity {
#     type = "SystemAssigned"
#   }

# }

# resource "null_resource" "mlextension" {
#     provisioner "local-exec" {
#         command = "az k8s-extension create --name mlextension --extension-type Microsoft.AzureML.Kubernetes --config enableTraining=True enableInference=True inferenceRouterServiceType=LoadBalancer allowInsecureConnections=True inferenceLoadBalancerHA=False --cluster-type managedClusters --cluster-name ${azurerm_kubernetes_cluster.aks.name} --resource-group ${azurerm_resource_group.default.name} --scope cluster" 
#     }
#     depends_on = [
#       azurerm_kubernetes_cluster.aks
#     ]
# }