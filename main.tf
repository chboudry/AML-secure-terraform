terraform {
  required_version = ">=1.0"
}

module "hub" {
  source                        = "./hub"
  name                          = var.name
  location                      = var.location
  dsvm_name                     = var.dsvm_name
  dsvm_admin_username           = var.dsvm_admin_username
  dsvm_host_password            = var.dsvm_host_password
  vnet_hub_address_space        = var.vnet_hub_address_space
  jumphost_subnet_address_space = var.jumphost_subnet_address_space
  bastion_subnet_address_space  = var.bastion_subnet_address_space
  firewall_subnet_address_space = var.firewall_subnet_address_space
  vnet_ml_address_space         = var.vnet_ml_address_space
  vnet_aks_address_space        = var.vnet_aks_address_space
}

module "spoke_ml" {
  source                           = "./spoke_ml"
  name                             = var.name
  location                         = var.location
  vnet_ml_address_space            = var.vnet_ml_address_space
  workspace_subnet_address_space   = var.workspace_subnet_address_space
  inference_subnet_address_space   = var.inference_subnet_address_space
  training_subnet_address_space    = var.training_subnet_address_space
  image_build_compute_name         = var.image_build_compute_name
  rg_hub_name                      = module.hub.rg_hub_name
  vnet_hub_id                      = module.hub.vnet_hub_id
  vnet_hub_name                    = module.hub.vnet_hub_name
  firewall_private_ip              = module.hub.firewall_private_ip
  law_id                           = module.hub.law_id
  dns_zone_dnsvault_id             = module.hub.dns_zone_dnsvault_id
  dns_zone_dnsstorageblob_id       = module.hub.dns_zone_dnsstorageblob_id
  dns_zone_dnsstoragefile_id       = module.hub.dns_zone_dnsstoragefile_id
  dns_zone_dnscontainerregistry_id = module.hub.dns_zone_dnscontainerregistry_id
  dns_zone_dnsazureml_id           = module.hub.dns_zone_dnsazureml_id
  dns_zone_dnsnotebooks            = module.hub.dns_zone_dnsnotebooks
}

module "aks" {
  source                   = "./spoke_aks"
  deployment_name          = var.name
  location                 = var.location
  rg_hub_name              = module.hub.rg_hub_name
  vnet_hub_id              = module.hub.vnet_hub_id
  vnet_hub_name            = module.hub.vnet_hub_name
  law_id                   = module.hub.law_id
  vnet_aks_address_space   = var.vnet_aks_address_space
  aks_subnet_address_space = var.aks_subnet_address_space
  firewall_private_ip      = module.hub.firewall_private_ip
}