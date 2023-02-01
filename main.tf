terraform {
  required_version = ">=1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.29.1"
    }
    azapi = {
      source  = "azure/azapi"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.33.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = ">= 2.17.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azapi" {
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)

  # using kubelogin to get an AAD token for the cluster.
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args = [
      "get-token",
      "--environment",
      "AzurePublicCloud",
      "--server-id",
      data.azuread_service_principal.aks_aad_server.application_id, # Note: The AAD server app ID of AKS Managed AAD is always 6dae42f8-4368-4678-94ff-3960e28e3630 in any environments.
      "--client-id",
      azuread_application.app.application_id, # SPN App Id created via terraform
      "--client-secret",
      azuread_service_principal_password.spn_password.value,
      "--tenant-id",
      data.azurerm_subscription.current.tenant_id, # AAD Tenant Id
      "--login",
      "spn"
    ]
  }
}


module "hub" {
  source = "./hub"
  name     = var.name
  location = var.location
  dsvm_name = var.dsvm_name
  dsvm_admin_username = var.dsvm_admin_username
  dsvm_host_password = var.dsvm_host_password

  vnet_hub_address_space = var.vnet_hub_address_space
  jumphost_subnet_address_space = var.jumphost_subnet_address_space
  bastion_subnet_address_space = var.bastion_subnet_address_space
  firewall_subnet_address_space = var.firewall_subnet_address_space

  vnet_ml_address_space = var.vnet_ml_address_space
  vnet_aks_address_space = var.vnet_aks_address_space
}

module "spoke_ml" {
  source = "./spoke_ml"
  #Variables
  #from var
  name     = var.name
  location = var.location

  vnet_ml_address_space = var.vnet_ml_address_space
  workspace_subnet_address_space = var.workspace_subnet_address_space
  inference_subnet_address_space = var.inference_subnet_address_space
  training_subnet_address_space = var.training_subnet_address_space

  image_build_compute_name = var.image_build_compute_name

  #from hub
  rg_hub_name = module.hub.rg_hub_name
  vnet_hub_id = module.hub.vnet_hub_id
  vnet_hub_name = module.hub.vnet_hub_name
  firewall_private_ip = module.hub.firewall_private_ip
  law_id = module.hub.law_id
  dns_zone_dnsvault_id = module.hub.dns_zone_dnsvault_id
  dns_zone_dnsstorageblob_id = module.hub.dns_zone_dnsstorageblob_id
  dns_zone_dnsstoragefile_id = module.hub.dns_zone_dnsstoragefile_id
  dns_zone_dnscontainerregistry_id = module.hub.dns_zone_dnscontainerregistry_id
  dns_zone_dnsazureml_id = module.hub.dns_zone_dnsazureml_id
  dns_zone_dnsnotebooks = module.hub.dns_zone_dnsnotebooks

  depends_on = [
    module.hub
  ]
}




/*module "aks" {
  source = "./spoke_aks"
  name     = "rg-${var.name}-aks"
  location = var.location
  rg_hub_name = azurerm_resource_group.hub_rg.name
  vnet_hub_name = azurerm_virtual_network.hub.name
  vnet_hub_id = azurerm_virtual_network.hub.id
  vnet_aks_address_space = var.vnet_aks_address_space

  providers = {
    azurerm = azurerm
    azapi = azapi
    azuread=azuread
  }
}*/