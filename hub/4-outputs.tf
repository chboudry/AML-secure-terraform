output "rg_hub_name" {
    value = azurerm_resource_group.hub_rg.name
}

output "vnet_hub_id" {
  value = azurerm_virtual_network.hub.id
}

output "vnet_hub_name" {
  value = azurerm_virtual_network.hub.name
}

output "firewall_private_ip" {
    value = azurerm_firewall.azure_firewall_instance.ip_configuration[0].private_ip_address
}

output "law_id" {
    value = azurerm_log_analytics_workspace.default.id
}

output "dns_zone_dnsvault_id" {
    value = azurerm_private_dns_zone.dnsvault.id
}

output "dns_zone_dnsstorageblob_id" {
    value = azurerm_private_dns_zone.dnsstorageblob.id
}

output "dns_zone_dnsstoragefile_id" {
    value = azurerm_private_dns_zone.dnsstoragefile.id
}

output "dns_zone_dnscontainerregistry_id" {
    value = azurerm_private_dns_zone.dnscontainerregistry.id
}

output "dns_zone_dnsazureml_id" {
    value = azurerm_private_dns_zone.dnsazureml.id
}

output "dns_zone_dnsnotebooks" {
    value = azurerm_private_dns_zone.dnsnotebooks.id
}
