resource "azapi_resource" "mlextension" {
  type = "Microsoft.KubernetesConfiguration/extensions@2022-11-01"
  name = "aksextml"
  parent_id = var.aks_id
  identity {
    type = "SystemAssigned"
  }
  body = jsonencode({
    properties = {
      autoUpgradeMinorVersion = true
      configurationProtectedSettings = {}
      configurationSettings = {
            allowInsecureConnections="true"
            clusterId= var.aks_id
            clusterPurpose= "DevTest"
            cluster_name= var.aks_name
            cluster_name_friendly= var.aks_name
            enableTraining="true"
            enableInference= "true"
            inferenceRouterHA= "true"
            inferenceRouterServiceType= "ClusterIP"
            //internalLoadBalancerProvider="azure"
            jobSchedulerLocation= var.aks_location
            location=var.aks_location
            domain= var.aks_location
            "prometheus.prometheusSpec.externalLabels.cluster.name"= var.aks_id
            //"nginxIngress.enabled"= "false"
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
    helm_release.nginx_ingress
  ]
}