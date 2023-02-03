variable "name" {}
variable "location" {}

variable "rg_hub_name" {}
variable "vnet_hub_id" {}
variable "vnet_hub_name" {}
variable "vnet_ml_address_space" {}

variable "workspace_subnet_address_space" {}
variable "inference_subnet_address_space" {}
variable "training_subnet_address_space" {}
variable "image_build_compute_name" {}

variable "firewall_private_ip" {}
variable "law_id" {}

variable "dns_zone_dnsvault_id" {}
variable "dns_zone_dnsstorageblob_id" {}
variable "dns_zone_dnsstoragefile_id" {}
variable "dns_zone_dnscontainerregistry_id" {}
variable "dns_zone_dnsazureml_id" {}
variable "dns_zone_dnsnotebooks" {}