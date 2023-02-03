variable "deployment_name" {}
variable "location" {}
variable "rg_hub_name" {}
variable "vnet_hub_name" {}
variable "vnet_hub_id" {}
variable "law_id" {}
variable "vnet_aks_address_space" {}
variable "aks_subnet_address_space" {}
variable "firewall_private_ip" {}


locals {
    rg_name = "rg-${var.deployment_name}-aks"
    vnet_name = "vnet-${var.deployment_name}-aks"
    aks_name = "aks-${var.deployment_name}"
}