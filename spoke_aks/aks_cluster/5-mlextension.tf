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
            internalLoadBalancerProvider="azure"
            jobSchedulerLocation= azurerm_kubernetes_cluster.aks.location
            location=azurerm_kubernetes_cluster.aks.location
            domain= azurerm_kubernetes_cluster.aks.location
            "prometheus.prometheusSpec.externalLabels.cluster.name"= azurerm_kubernetes_cluster.aks.id
            "nginxIngress.enabled"= "false"
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