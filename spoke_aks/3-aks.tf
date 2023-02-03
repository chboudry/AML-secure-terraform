module "aks-cluster" {
  source       = "./aks_cluster"
  deployment_name = var.deployment_name
  aks_name = local.aks_name 
  rg_name = azurerm_resource_group.aks.name
  location     = azurerm_resource_group.aks.location
  subnet_id = azurerm_subnet.snet-aks.id
  law_id = var.law_id
}

data "azurerm_kubernetes_cluster" "default" {
  depends_on          = [module.aks-cluster] # refresh cluster state before reading
  name                = local.aks_name 
  resource_group_name = azurerm_resource_group.aks.name
}

provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.default.kube_config.0.host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.default.kube_config.0.host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.cluster_ca_certificate)
  }
}

module "kubernetes-config" {
  depends_on   = [module.aks-cluster]
  source       = "./kubernetes_config"
  aks_name = local.aks_name 
  kubeconfig   = data.azurerm_kubernetes_cluster.default.kube_config_raw
}